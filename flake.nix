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
																	CREATION_TIME="$( stat --format "%W" "${ secret-directory }/$HASH/mount" )"
																	${ log }/bin/log \
																		"setup" \
																		"bad" \
																		"$HASH" \
																		"$ORIGINATOR_PID" \
																		"$STATUS" \
																		"$( cat "${ secret-directory }/$HASH/init.standard-error" )" \
																		"$( cat "${ secret-directory }/$HASH/init.standard-output" )" \
																		"$GARBAGE" \
																		"$CREATION_TIME" \
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
echo BEFORE CREATION >> /tmp/DEBUG
																	CREATION_TIME="$( stat --format "%W" "${ secret-directory }/$HASH/mount" )"
echo "AFTER CREATION CREATION_TIME=$CREATION_TIME" >> /tmp/DEBUG
																	${ log }/bin/log \
																		"setup" \
																		"good" \
																		"$HASH" \
																		"$ORIGINATOR_PID" \
																		"$STATUS" \
																		"$( cat "${ secret-directory }/$HASH/init.standard-error" )" \
																		"$( cat "${ secret-directory }/$HASH/init.standard-output" )" \
																		"" \
																		"$CREATION_TIME"
																		${ builtins.toString lease } &
echo "AFTER LOG COMMAND lease=${ builtins.toString lease }" >> /tmp/DEBUG
																	sleep ${ builtins.toString lease }
echo "AFTER SLEEP" >> /tmp/DEBUG
																	tail --follow /dev/null --pid "$ORIGINATOR_PID"
echo "AFTER 201" >> /tmp/DEBUG
																	flock -u 201
echo "AFTER 201" >> /tmp/DEBUG
																	flock -u 202
echo "AFTER TEARDOWN" >> /tmp/DEBUG
																	${ teardown }/bin/teardown "$HASH" "$ORIGINATOR_PID" "$STATUS" "$CREATION_TIME"
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
echo IN LOG A >> /tmp/DEBUG
																	MODE="$1"
echo IN LOG B >> /tmp/DEBUG
																	TYPE="$2"
echo IN LOG C >> /tmp/DEBUG
																	HASH="$3"
echo IN LOG D >> /tmp/DEBUG
																	ORIGINATOR_PID="$4"
echo IN LOG E >> /tmp/DEBUG
																	STATUS="$5"
echo IN LOG F >> /tmp/DEBUG
																	STANDARD_ERROR="$6"
echo IN LOG G >> /tmp/DEBUG
																	STANDARD_OUTPUT="$7"
echo IN LOG H >> /tmp/DEBUG
																	# CREATION_TIME="$8"
echo IN LOG I >> /tmp/DEBUG
																	GARBAGE="$9"
echo IN LOG J >> /tmp/DEBUG
																	TIMESTAMP="$( date +%s )"
echo IN LOG K >> /tmp/DEBUG
																	CURRENT_TIME=${ builtins.toString current-time }
echo IN LOG L >> /tmp/DEBUG
																	CREATION_TIME="$( stat --format "%W" "${ secret-directory }/$HASH/mount" )"
echo IN LOG M >> /tmp/DEBUG
																	TEMP_FILE="$( mktemp )"
echo IN LOG N >> /tmp/DEBUG
																	jq \
																		--null-input \
																		--arg CREATION_TIME "$CREATION_TIME" \
																		--arg CURRENT_TIME "$CURRENT_TIME" \
																		--arg HASH "$HASH" \
																		--arg GARBAGE "$GARBAGE" \
																		--arg MODE "$MODE" \
																		--arg ORIGINATOR_PID "$ORIGINATOR_PID" \
																		--arg STANDARD_ERROR "$STANDARD_ERROR" \
																		--arg STANDARD_OUTPUT "$STANDARD_OUTPUT" \
																		--arg STATUS "$STATUS" \
																		--arg TIMESTAMP "$TIMESTAMP" \
																		--arg TYPE "$TYPE" \
																		'{ "creation-time" : $CREATION_TIME , "current-time" : $CURRENT_TIME , "hash" : $HASH , "mode" : $MODE , "garbage": $GARBAGE , "originator-pid" : $ORIGINATOR_PID , path : ${ builtins.toJSON path } , "standard-error" : $STANDARD_ERROR , "standard-output" : $STANDARD_OUTPUT , "status" : $STATUS , "timestamp" : $TIMESTAMP , "type" : $TYPE  }' | yq --yaml-output "[.]" > "$TEMP_FILE"
echo IN LOG NN >> /tmp/DEBUG
																	exec 203> ${ secret-directory }/log.lock
echo IN LOG O >> /tmp/DEBUG
																	flock -x 203
echo IN LOG P >> /tmp/DEBUG
																	cat "$TEMP_FILE" >> ${ secret-directory }/log.yaml
echo IN LOG Q >> /tmp/DEBUG
																	flock -u 203
echo IN LOG R >> /tmp/DEBUG
																	rm "$TEMP_FILE"
echo IN LOG S >> /tmp/DEBUG
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
																	CREATION_TIME="$( stat --format "%W" "${ secret-directory }/$HASH/mount" )"
																	${ log }/bin/log \
																		"setup" \
																		"null" \
																		"$HASH" \
																		"$ORIGINATOR_PID" \
																		"" \
																		"" \
																		"" )" \
																		"" \
																		"$CREATION_TIME"
																		${ builtins.toString lease } &
																	sleep ${ builtins.toString lease }
																	tail --follow /dev/null --pid "$ORIGINATOR_PID"
																	flock -u 201
																	flock -u 201
																	exec 203> "${ secret-directory }/log.lock"
																	flock -x 203
																	${ teardown }/bin/teardown "$HASH" "$ORIGINATOR_PID" "" "$CREATION_TIME"
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
																	CREATION_TIME="$( stat --format "%W" "${ secret-directory }/$HASH/mount" )"
																	${ log }/bin/log \
																		"setup" \
																		"stale" \
																		"$HASH" \
																		"$ORIGINATOR_PID" \
																		"" \
																		"" \
																		"" \
																		"" \
																		"$CREATION_TIME"
																		${ builtins.toString lease } &
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
echo IN TEARDOWN 1 >> /tmp/DEBUG
																				HASH="$1"
echo IN TEARDOWN 2 >> /tmp/DEBUG
																				ORIGINATOR_PID="$2"
																				STATUS="$3"
echo "IN TEARDOWN 3" >> /tmp/DEBUG
																				CREATION_TIME="$4"
echo "IN TEARDOWN 33 EXPECTED=$CREATION_TIME" >> /tmp/DEBUG
echo "IN TEARDOWN 33 OBSERVED=$( stat --format "%W" "${ secret-directory }/$HASH/mount" )" >> /tmp/DEBUG
																				if [ ! -d "${ secret-directory }/$HASH" ] || [ ! -f "${ secret-directory }/$HASH/mount" ] || [ "$( stat --format "%W" "${ secret-directory }/$HASH/mount" )" != "$CREATION_TIME" ]
																				then
echo IN TEARDOWN 3.1 >> /tmp/DEBUG

																					${ log }/bin/log \
																						"teardown" \
																						"aborted" \
																						"$HASH" \
																						"$ORIGINATOR_PID" \
																						"" \
																						"" \
																						"" \
																						"" \
																						"$CREATION_TIME" \
																						${ builtins.toString lease }
echo IN TEARDOWN 3.2 >> /tmp/DEBUG

																				else
echo IN TEARDOWN 3.3 >> /tmp/DEBUG
																					exec 201> "${ secret-directory }/$HASH/exclusive-lock"
echo IN TEARDOWN 3.4 >> /tmp/DEBUG
																					flock -x 201
echo IN TEARDOWN 3.5 >> /tmp/DEBUG
																					exec 202> "${ secret-directory }/$HASH/shared-lock"
echo IN TEARDOWN 3.6 >> /tmp/DEBUG
																					flock -x 202																				
echo IN TEARDOWN 3.7 >> /tmp/DEBUG
																					GARBAGE="$( mktemp --dry-run --suffix ".tar.zst" )"
echo IN TEARDOWN 3.8 >> /tmp/DEBUG
																					tar --create --file - -C "${ secret-directory }" "$HASH" | zstd -T1 -19 > "$GARBAGE"
echo IN TEARDOWN 3.9 >> /tmp/DEBUG
																					rm --recursive --force "${ secret-directory }/$HASH"
echo IN TEARDOWN 3.10 >> /tmp/DEBUG
																					flock -u 202
echo IN TEARDOWN 3.11 >> /tmp/DEBUG
																					flock -u 201
echo IN TEARDOWN 3.12 >> /tmp/DEBUG
																					${ log }/bin/log \
																						"teardown" \
																						"active" \
																						"$HASH" \
																						"$ORIGINATOR_PID" \
																						"" \
																						"" \
																						"" \
																						"$GARBAGE" \
																						"$CREATION_TIME" \
																						${ builtins.toString lease }
echo IN TEARDOWN 3.13 >> /tmp/DEBUG
																					exec 204> ${ secret-directory }/collect-garbage.lock
echo IN TEARDOWN 3.14 >> /tmp/DEBUG
																					flock -x 204
echo IN TEARDOWN 3.15 >> /tmp/DEBUG
																					nix-collect-garbage
echo IN TEARDOWN 3.16 >> /tmp/DEBUG
																					flock -u 204
echo IN TEARDOWN 3.17 >> /tmp/DEBUG
																				fi
																			''
																		else
																			''
																				HASH="$1"
																				ORIGINATOR_PID="$2"
																				STATUS="$3"
																				CREATION_TIME="$4"
																				if [ ! -d "${ secret-directory }/$HASH" ] || [ ! -f "${ secret-directory }/$HASH/mount" ] || [ "$( stat --format "%W" "${ secret-directory }/$HASH/mount" )" != "$CREATION_TIME" ]
																				then
																					${ log }/bin/log \
																						"teardown" \
																						"aborted" \
																						"$HASH" \
																						"$ORIGINATOR_PID" \
																						"" \
																						"" \
																						"$CREATION_TIME" \
																						${ builtins.toString lease }
																				else
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
																					${ log }/bin/log \
																						"teardown" \
																						"null" \
																						"$HASH" \
																						"$ORIGINATOR_PID" \
																						"" \
																						"$( cat "${ secret-directory }/$HASH/release.standard-error )" \
																						"$( cat "${ secret-directory }/$HASH/release.standard-output )" \
																						"$GARBAGE" \
																						${ builtins.toString lease }
																					tar --create --file - -C "${ secret-directory }" "$HASH" | zstd -T1 -19 > "$GARBAGE"
																					rm --recursive --force "${ secret-directory }/$HASH"
																					flock -u 202
																					flock -u 201
																					exec 204> ${ secret-directory }/collect-garbage.lock
																					flock -x 204
																					nix-collect-garbage
																					flock -u 204
																				fi
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
															if [[ -f "${ secret-directory }/$HASH/mount" ]]
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
															if [[ -f "${ secret-directory }/$HASH/mount" ]]
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
