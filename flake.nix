{
	inputs = { } ;
	outputs =
		{ self } :
			{
				lib.implementation =
					{
						error ? 64 ,
						init-inputs ? [ ] ,
						init-text ? null ,
						length ? 64 ,
						lease ? 0 ,
						nixpkgs ,
						path ? null ,
						release-inputs ? [ ] ,
						release-text ? null ,
						secret-directory ? "$TMPDIR/secret" ,
						seed ? null ,
						system
					} @primary :
						let
							application =
								pkgs.writeShellApplication
									{
										name = "application" ;
										runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.flock pkgs.procps ] ;
										text =
											let
												bad =
													pkgs.writeShellApplication
														{
															name = "bad" ;
															runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.yq ] ;
															text =
																''
																	HASH="$1"
																	FLAG="$2"
																	ORIGINATOR_PID="$3"
																	STATUS="$4"
																	exec 202> "${ secret-directory }/$HASH/shared-lock"
																	flock -s 202
																	rm "$FLAG"
																	exec 201> "${ secret-directory }/$HASH/exclusive-lock"
																	flock -s 201
																	exec 203> "${ secret-directory }/log.lock"
																	flock -x 203
																	jq --null-input --arg HASH "$HASH" --arg ORIGINATOR_PID "$ORIGINATOR_PID" --arg STATUS "$STATUS" --arg STANDARD_ERROR "$( cat "${ secret-directory }/$HASH/init.standard-error" )" --arg STANDARD_OUTPUT "$( cat "${ secret-directory }/$HASH/init.standard-output" )" '{ "mode" : "init" , "type" : "good" , "hash" : $HASH , "originator-pid" : $ORIGINATOR_PID , "status" : $STATUS , "standard-error" : $STANDARD_ERROR , "standard-output" : $STANDARD_OUTPUT  }' | yq --yaml-output "." > "${ secret-directory }/log.yaml"
																	tail --follow /dev/null --pid "$ORIGINATOR_PID"
																	flock -u 203
																	flock -u 201
																	flock -u 201
																'' ;
														} ;
												good =
													pkgs.writeShellApplication
														{
															name = "good" ;
															runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.yq ] ;
															text =
																''
																	HASH="$1"
																	FLAG="$2"
																	ORIGINATOR_PID="$3"
																	STATUS="$4"
																	exec 202> "${ secret-directory }/$HASH/shared-lock"
																	flock -s 202
																	rm "$FLAG"
																	exec 201> "${ secret-directory }/$HASH/exclusive-lock"
																	flock -s 201
																	ln --symbolic ${ teardown }/bin/teardown "${ secret-directory }/$HASH/teardown"
																	exec 203> "${ secret-directory }/log.lock"
																	flock -x 203
																	jq --null-input --arg HASH "$HASH" --arg ORIGINATOR_PID "$ORIGINATOR_PID" --arg STATUS "$STATUS" --arg STANDARD_ERROR "$( cat "${ secret-directory }/$HASH/init.standard-error" )" --arg STANDARD_OUTPUT "$( cat "${ secret-directory }/$HASH/init.standard-output" )" --arg LEASE ${ builtins.toString lease } '{ "mode" : "setup" , "type" : "good" , "hash" : $HASH , "originator-pid" : ORIGINATOR_PID , "status" : $STATUS , "standard-error" : $STANDARD_ERROR , "standard-output" : $STANDARD_OUTPUT , "lease" : $LEASE  }' | yq --yaml-output "." > "${ secret-directory }/log.yaml"
																	sleep ${ builtins.toString lease }
																	tail --follow /dev/null --pid "$ORIGINATOR_PID"
																	flock -u 203
																	flock -u 201
																	flock -u 201
																'' ;
														} ;
												hash = builtins.hashString "sha512" ( builtins.toJSON primary ) ;
												init-application =
													pkgs.buildFHSUserEnv
														{
															extraBwrapArgs =
																[
																	"--bind ${ secret-directory }/$HASH/mount /mount"
																	"--bind-ro ${ secret-directory } ${ secret-directory }"
																	"--tmpfs /work"
																] ;
															name = "init-application" ;
															runScript =
																let
																	script =
																		pkgs.writeShellApplication
																			{
																				name = "script" ;
																				runtimeInputs = init-inputs ;
																				text = init-text ;
																			} ;
																	in "${ script }/bin/script" ;
														} ;
												null =
													pkgs.writeShellApplication
														{
															name = "null" ;
															runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.yq ] ;
															text =
																''
																	HASH="$1"
																	FLAG="$2"
																	ORIGINATOR_PID="$3"
																	STATUS="$4"
																	exec 202> "${ secret-directory }/$HASH/shared-lock"
																	flock -s 202
																	rm "$FLAG"
																	exec 201> "${ secret-directory }/$HASH/exclusive-lock"
																	flock -s 201
																	ln --symbolic ${ teardown }/bin/teardown "${ secret-directory }/$HASH/teardown
																	exec 203> ${ secret-directory }/log.lock
																	flock -x 203
																	jq --null-input --arg HASH "$HASH" --arg ORIGINATOR_PID "ORIGINATOR_PID" --arg LEASE ${ builtins.toString lease } '{ "mode" : "setup" , "type" : "null" , "hash" : $HASH , "originator-pid" : $ORIGINATOR_PID , "lease" : $LEASE  }' | yq --yaml-output "." > ${ secret-directory }/log.yaml
																	sleep ${ builtins.toString lease }
																	tail --follow /dev/null --pid "$ORIGINATOR_PID"
																	flock -u 203
																	flock -u 201
																	flock -u 201
																'' ;
														} ;

												stale =
													pkgs.writeShellApplication
														{
															name = "stale" ;
															runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.yq ] ;
															text =
																''
																	HASH="$1"
																	FLAG="$2"
																	ORIGINATOR_PID="$3"
																	exec 202> "${ secret-directory }/$HASH/shared-lock"
																	flock -s 202
																	rm "$FLAG"
																	exec 201> "${ secret-directory }/$HASH/exclusive-lock"
																	flock -s 201
																	exec 203> "${ secret-directory }/log.lock"
																	flock -x 203
																	jq --null-input --arg HASH "$HASH" --arg ORIGINATOR_PID "$ORIGINATOR_PID" '{ "mode" : "setup" , "type" : "stale" , "hash" : $HASH , "originator-pid" : $ORIGINATOR_PID  }' | yq --yaml-output "." > "${ secret-directory }/log.yaml"
																	tail --follow /dev/null --pid "$ORIGINATOR_PID"
																	flock -u 203
																	flock -u 201
																	flock -u 201
																'' ;
														} ;
												teardown =
													pkgs.writeShellApplication
														{
															name = "teardown" ;
															text =
																let
																	release-application =
																		pkgs.buildFHSUserEnv
																			{
																				extraBwrapArgs =
																					[
																						"--bind-ro ${ secret-directory }/$HASH/mount /mount"
																						"--bind-ro ${ secret-directory } ${ secret-directory }"
																						"--tmpfs /work"
																					] ;
																				name = "release-application" ;
																				runScript =
																					let
																						script =
																							pkgs.writeShellApplication
																								{
																									name = "script" ;
																									runtimeInputs = release-inputs ;
																									text = release-text ;
																								} ;
																						in "${ script }/bin/script" ;
																			} ;
																	in
																		if builtins.typeOf release-text == "null" then
																			''
																				HASH="$( basename "$( dirname "$0" )" )"
																				exec 201> "$ secret-directory }/$HASH/exclusive-lock"
																				flock -x 201
																				exec 202> "${ secret-directory }/$HASH/shared-lock"
																				flock -x 202
																				exec 203> "${ secret-directory }/log.lock"
																				flock -x 203
																				jq --null-input --arg HASH "$HASH" '{ "mode" : "teardown" , "hash" : $HASH }' | yq --yaml-output "." > "${ secret-directory }/log.yaml"
																				tar --create --file - "${ secret-directory }/$HASH" | zstd -T1 --ultra -22 -o "$( mktemp --dry-run --suffix ".tar.zst" )"
																				rm --recursive --force "${ secret-directory }/$HASH"
																				flock -u 203
																				flock -u 202
																				flock -u 201
																			''
																		else
																			''
																				HASH="$( basename "$( dirname "$0" )" )"
																				export HASH
																				exec 201> "$ secret-directory }/$HASH/exclusive-lock"
																				flock -x 201
																				exec 202> "${ secret-directory }/$HASH/shared-lock"
																				flock -x 202
																				if ${ release-application }/bin/release > "${ secret-directory }/$HASH/release.standard-output" 2> "${ secret-directory }/$HASH/release.standard-error"
																				then
																					STATUS="$?"
																				else
																					STATUS="$?"
																				fi
																				exec 203> ${ secret-directory }/log.lock
																				flock -x 203
																				jq --null-input --arg HASH "$HASH" --arg STATUS "$STATUS" --arg STANDARD_ERROR "$( cat "${ secret-directory }/$HASH/release.standard-error" ) --arg STANDARD_OUTPUT "$( cat "${ secret-directory }/$HASH/release.standard-output" )" '{ "mode" : "teardown" , "hash" : $HASH , "status" : $STATUS , "standard-error" : $STANDARD_ERROR , "standard-output" : $STANDARD_OUTPUT  }' | yq --yaml-output "." > ${ secret-directory }/log.yaml
																				tar --create --file - ${ secret-directory }/$HASH | zstd -T1 --ultra -22 -o "$( mktemp --dry-run --suffix ".tar.zst" )"
																				rm --recursive --force "${ secret-directory }/$HASH"
																				flock -u 203
																				flock -u 202
																				flock -u 201
																			'' ;
														} ;
												in
													if builtins.typeOf init-text == "null" then
														''
															PARENT_0_PID="$$"
															PARENT_1_PID=$( ps -p "$PARENT_0_PID" -o ppid= | xargs )
															PARENT_2_PID=$( ps -p "$PARENT_1_PID" -o ppid= | xargs )
															PARENT_3_PID=$( ps -p "$PARENT_2_PID" -o ppid= | xargs )
															HASH="$( echo "${ hash } | sha512sum | cut --bytes -${ builtins.toString length } )"
															mkdir --parents "${ secret-directory }/$HASH"
															exec 201> "${ secret-directory }/$HASH/exclusive-lock"
															flock -x 201
															exec 202> "${ secret-directory }/$HASH/shared-lock"
															flock -s 202
															FLAG="$( mktemp "${ secret-directory }/$HASH/XXXXXXXX" )"
															if [[ -f "${ secret-directory }/$HASH/flag" ]]
															then
																nohup ${ stale }/bin/stale "$HASH" "$FLAG" "$ORIGINATOR_PID"
																inotifywait --event delete "$FLAG" --quiet
																flock -u 201
																rm "$STANDARD_INPUT"
																echo "${ secret-directory }/$HASH/mount"																
																exit 0
															else
																mkdir "${ secret-directory }/$HASH/mount"
																touch "${ secret-directory }/$HASH/flag"
																nohup ${ null }/bin/null "$HASH" "$FLAG" "$ORIGINATOR_PID"
																inotifywati --event delete "$FLAG" --quiet
																flock -u 201
																rm "$STANDARD_INPUT"
																echo "${ secret-directory }/$HASH/mount"
																exit 0
															fi
														''
													else
														''
															PARENT_0_PID="$$"
															PARENT_1_PID=$( ps -p "$PARENT_0_PID" -o ppid= | xargs )
															PARENT_2_PID=$( ps -p "$PARENT_1_PID" -o ppid= | xargs )
															PARENT_3_PID=$( ps -p "$PARENT_2_PID" -o ppid= | xargs )
															STANDARD_INPUT="$( mktemp )"
															if [[ -f /proc/self/fd/0 ]]
															then
																HAS_STANDARD_INPUT=true
																STANDARD_INPUT="$( cat )"
																ORIGINATOR_PID="$PARENT_3_PID"
															elif [[ -p /proc/self/fd/0 ]]
															then
																HAS_STANDARD_INPUT=true
																cat > "$STANDARD_INPUT"
																ORIGINATOR_PID="$PARENT_3_PID"
															else
																HAS_STANDARD_INPUT=false
																cat > "$STANDARD_INPUT"
																ORIGINATOR_PID="$PARENT_2_PID"
															fi
															ARGUMENTS=( "$@" )
															HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[*]" "}" ] } $( cat "$STANDARD_INPUT" ) $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )"
															export HASH
															mkdir --parents "${ secret-directory }/$HASH"
															exec 201> "${ secret-directory }/$HASH/exclusive-lock"
															flock -x 201
															exec 202> "${ secret-directory }/$HASH/shared-lock"
															flock -s 202
															FLAG="$( mktemp "${ secret-directory }/$HASH/XXXXXXXX" )"
															if [[ -f "${ secret-directory }/$HASH/flag" ]]
															then
																nohup ${ stale }/bin/stale "$HASH" "$FLAG" "$ORIGINATOR_PID" &
																inotifywait --event delete "$FLAG" --quiet
																flock -u 201
																rm "$STANDARD_INPUT"
																echo "${ secret-directory }/$HASH/mount"																
																exit 0
															else
																mkdir "${ secret-directory }/$HASH/mount"
																if "$HAS_STANDARD_INPUT"
																then
																	if ${ init-application }/bin/init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" < "$STANDARD_INPUT" > "${ secret-directory }/$HASH/init.standard-output" 2> "${ secret-directory }/$HASH/init.standard-error"
																	then
																		nohup ${ good }/bin/good "$HASH" "$FLAG" "$ORIGINATOR_PID" "$STATUS" &
																		touch "${ secret-directory }/$HASH/flag"
																		inotifywait --event delete "$FLAG" --quiet
																		flock -u 201
																		rm "$STANDARD_INPUT"
																		echo "${ secret-directory }/$HASH/mount"
																		exit 0
																	else
																		nohup ${ bad }/bin/bad "$HASH" "$FLAG" "$ORIGINATOR_PID" "$STATUS" &
																		inotifywait --event delete "$FLAG" --quiet
																		flock -u 201
																		rm "$STANDARD_INPUT"
																		exit ${ builtins.toString error }
																	fi
																else
																	if ${ init-application }/bin/init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "${ secret-directory }/$HASH/init.standard-output" 2> "${ secret-directory }/$HASH/init.standard-error"
																	then
																		nohup ${ good }/bin/good "$HASH" "$FLAG" "$ORIGINATOR_PID" "$STATUS" &
																		inotifywait --event delete "$FLAG" --quiet
																		flock -u 201
																		rm "$STANDARD_INPUT"
																		echo "${ secret-directory }/$HASH/mount"
																		exit 0
																	else
																		nohup ${ bad }/bin/bad "$HASH" "$FLAG" "$ORIGINATOR_PID" "$STATUS" &
																		inotifywait --event delete "$FLAG" --quiet
																		flock -u 201
																		rm "$STANDARD_INPUT"
																		exit ${ builtins.toString error }
																	fi
																fi
															fi
														'' ;
									} ;
							pkgs = builtins.getAttr system nixpkgs.legacyPackages ;
							in "${ application }/bin/application" ;
			} ;
}
