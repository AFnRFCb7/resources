{
	inputs = { } ;
	outputs =
		{ self } :
			{
				lib.implementation =
					{
						current-time ? 0 ,
						error ? 64 ,
						init-inputs ? [ ] ,
						init-text ? null ,
						length ? 64 ,
						lease ? 0 ,
						nixpkgs ,
						path ? null ,
						release-inputs ? [ ] ,
						release-text ? null ,
						secret-directory ? "/tmp" ,
						system
					} @primary :
						let
							application =
								pkgs.writeShellApplication
									{
										name = "application" ;
										runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.flock pkgs.inotify-tools pkgs.procps ] ;
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
																	GARBAGE="$( mktemp --dry-run suffix ".tar.zst" )"
																	exec 202> "${ secret-directory }/$HASH/shared-lock"
																	flock -s 202
																	rm "$FLAG"
																	exec 201> "${ secret-directory }/$HASH/exclusive-lock"
																	flock -x 201
																	${ log }/bin/log \
																		"setup" \
																		"bad" \
																		"$HASH" \
																		"$ORIGINATOR_PID" \
																		"$STATUS" \
																		"$( cat "${ secret-directory }/$HASH/init.standard-error" )" \
																		"$( cat "${ secret-directory }/$HASH/init.standard-output" )" \
																		"$GARBAGE" \
																		${ builtins.toString lease } &
																	tar --create --file - "${ secret-directory }/$HASH" | zstd -T1 --ultra -22 -o "$GARBAGE"
																	rm --recursive --force "${ secret-directory }/$HASH"																
																	flock -u 201
																	flock -u 202
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
																	${ log }/bin/log \
																		"setup" \
																		"good" \
																		"$HASH" \
																		"$ORIGINATOR_PID" \
																		"$STATUS" \
																		"$( cat "${ secret-directory }/$HASH/init.standard-error" )" \
																		"$( cat "${ secret-directory }/$HASH/init.standard-output" )" \
																		"" \
																		${ builtins.toString lease } &
																	sleep ${ builtins.toString lease }
																	tail --follow /dev/null --pid "$ORIGINATOR_PID"
																	flock -u 201
																	flock -u 202
																	touch "${ secret-directory }/$HASH/TEARDOWN_FLAG"
																	${ teardown }/bin/teardown "$HASH" "$ORIGINATOR_PID" "$STATUS"
																'' ;
														} ;
												hash = builtins.hashString "sha512" ( builtins.toJSON primary ) ;
												init-application =
													pkgs.buildFHSUserEnv
														{
															extraBwrapArgs =
																[
																	"--bind ${ secret-directory }/$HASH/mount /mount"
																	"--ro-bind ${ secret-directory } ${ secret-directory }"
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
												log =
													pkgs.writeShellApplication
														{
															name = "log" ;
															runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.yq ] ;
															text =
																''
																	MODE="$1"
																	TYPE="$2"
																	HASH="$3"
																	ORIGINATOR_PID="$4"
																	STATUS="$5"
																	STANDARD_ERROR="$6"
																	STANDARD_OUTPUT="$7"
																	GARBAGE="$8"
																	TIMESTAMP="$( date +%s )"
																	CURRENT_TIME=${ builtins.toString current-time }
																	exec 203> "${ secret-directory }/log.lock"
																	flock -x 203
																	jq \
																		--null-input \
																		--arg CURRENT_TIME "$CURRENT_TIME"
																		--arg HASH "$HASH" \
																		--arg GARBAGE "$GARBAGE" \
																		--arg MODE "$MODE" \
																		--arg ORIGINATOR_PID "$ORIGINATOR_PID" \
																		--arg STANDARD_ERROR "$STANDARD_ERROR" \
																		--arg STANDARD_OUTPUT "$STANDARD_OUTPUT" \
																		--arg STATUS "$STATUS" \
																		--arg TIMESTAMP "$TIMESTAMP" \
																		--arg TYPE "$TYPE" \
																		'{ "current-time" : $CURRENT_TIME , "hash" : $HASH , "mode" : $MODE , "garbage": $GARBAGE , "originator-pid" : $ORIGINATOR_PID , "standard-error" : $STANDARD_ERROR , "standard-output" : $STANDARD_OUTPUT , "status" : $STATUS , "timestamp" : $TIMESTAMP , "type" : $TYPE  }' | yq --yaml-output "[.]" >> ${ secret-directory }/log.yaml
																	flock -u 203
																'' ;
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
																	exec 203> ${ secret-directory }/log.lock
																	flock -x 203
																	jq --null-input --arg HASH "$HASH" --arg ORIGINATOR_PID "ORIGINATOR_PID" --arg LEASE ${ builtins.toString lease } '{ "mode" : "setup" , "type" : "null" , "hash" : $HASH , "originator-pid" : $ORIGINATOR_PID , "lease" : $LEASE  }' | yq --yaml-output "." > ${ secret-directory }/log.yaml
																	sleep ${ builtins.toString lease }
																	tail --follow /dev/null --pid "$ORIGINATOR_PID"
																	flock -u 203
																	flock -u 201
																	flock -u 201
																	${ teardown }/bin/teardown "$HASH" "$ORIGINATOR_PID" ""
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
																	${ teardown }/bin/teardown "$HASH"
																'' ;
														} ;
												teardown =
													pkgs.writeShellApplication
														{
															name = "teardown" ;
															runtimeInputs = [ pkgs.coreutils pkgs.flock pkgs.gnutar pkgs.nix pkgs.zstd ] ;
															text =
																let
																	release-application =
																		pkgs.buildFHSUserEnv
																			{
																				extraBwrapArgs =
																					[
																						"--ro-bind ${ secret-directory }/$HASH/mount /mount"
																						"--ro-bind ${ secret-directory } ${ secret-directory }"
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
																				HASH="$1"
																				ORIGINATOR_PID="$2"
																				GARBAGE="$( mktemp --dry-run --suffix ".tar.zst" )"
																				exec 201> "${ secret-directory }/$HASH/exclusive-lock"
																				flock -x 201
																				exec 202> "${ secret-directory }/$HASH/shared-lock"
																				flock -x 202
																				
																				tar --create --file - -C "${ secret-directory }" "$HASH" | zstd -T1 -19 > "$GARBAGE"
																				rm --recursive --force "${ secret-directory }/$HASH"
																				flock -u 202
																				flock -u 201
																				${ log }/bin/log \
																					"teardown" \
																					"null" \
																					"$HASH" \
																					"$ORIGINATOR_PID" \
																					"" \
																					"" \
																					"" \
																					"$GARBAGE" \
																					${ builtins.toString lease }
																				exec 204> ${ secret-directory }/collect-garbage.lock
																				flock -x 204
																				nix-collect-garbage
																				flock -u 204
																			''
																		else
																			''
																				HASH="$1"
																				export HASH
																				GARBAGE="$( mktemp --dry-run --suffix ".tar.zst" )"
																				exec 201> "${ secret-directory }/$HASH/exclusive-lock"
																				flock -x 201
																				exec 202> "${ secret-directory }/$HASH/shared-lock"
																				flock -x 202
																				if ${ release-application }/bin/release > "${ secret-directory }/$HASH/release.standard-output" 2> "${ secret-directory }/$HASH/release.standard-error"
																				then
																					STATUS="$?"
																				else
																					STATUS="$?"
																				fi
																				STANDARD_ERROR="$( cat "${ secret-directory }/$HASH/release.standard-error" )"
																				STANDARD_OUTPUT="$( cat "${ secret-directory }/$HASH/release.standard-output" )"
																				tar --create --file - -C "${ secret-directory }" "$HASH" | zstd -T1 -19 > "$GARBAGE"
																				rm --recursive --force "${ secret-directory }/$HASH"
																				flock -u 202
																				flock -u 201
																				${ log }/bin/log \
																					"teardown" \
																					"null" \
																					"$HASH" \
																					"$ORIGINATOR_PID" \
																					"" \
																					"" \
																					"" \
																					"$GARBAGE" \
																					${ builtins.toString lease }
																				exec 204> ${ secret-directory }/collect-garbage.lock
																				flock -x 204
																				nix-collect-garbage
																				flock -u 204
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
																		nohup ${ good }/bin/good "$HASH" "$FLAG" "$ORIGINATOR_PID" "$?" > /dev/null 2>&1 &
																		touch "${ secret-directory }/$HASH/flag"
																		inotifywait --event delete_self "$FLAG" --quiet > /dev/null 2>&1
																		flock -u 201
																		rm "$STANDARD_INPUT"
																		echo "${ secret-directory }/$HASH/mount"
																		exit 0
																	else
																		nohup ${ bad }/bin/bad "$HASH" "$FLAG" "$ORIGINATOR_PID" "$?" > /dev/null 2>&1 &
																		inotifywait --event delete "$FLAG" --quiet
																		flock -u 201
																		rm "$STANDARD_INPUT"
																		exit ${ builtins.toString error }
																	fi
																else
																	if ${ init-application }/bin/init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "${ secret-directory }/$HASH/init.standard-output" 2> "${ secret-directory }/$HASH/init.standard-error"
																	then
																		nohup ${ good }/bin/good "$HASH" "$FLAG" "$ORIGINATOR_PID" "$?" > /dev/null 2>&1 &
																		inotifywait --event delete_self "$FLAG" --quiet > /dev/null 2>&1
																		flock -u 201
																		rm "$STANDARD_INPUT"
																		echo "${ secret-directory }/$HASH/mount"
																		exit 0
																	else
																		nohup ${ bad }/bin/bad "$HASH" "$FLAG" "$ORIGINATOR_PID" "$?" > /dev/null 2>&1 &
																		inotifywait --event delete_self "$FLAG" --quiet > /dev/null 2>&1
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
