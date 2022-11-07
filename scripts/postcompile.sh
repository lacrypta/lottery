#! /usr/bin/env -S bash
# -*- coding: ascii -*-

LC_ALL=C
POSIXLY_CORRECT=1
unset -f builtin
unset -v POSIXLY_CORRECT

get_command_or_fail() {
    RESULT="$(/usr/bin/env which "${1}")"
    builtin echo "${RESULT:?\'"${1}"\' command not found}"
}

THE_CP="$(get_command_or_fail cp)"
THE_FIND="$(get_command_or_fail find)"
THE_GIT="$(get_command_or_fail git)"
THE_MKDIR="$(get_command_or_fail mkdir)"

builtin cd "$("${THE_GIT}" rev-parse --show-toplevel || builtin true)" || exit 1

while builtin read -r contract; do
    newFileName="${contract/contracts/abi}"
    newFileName="${newFileName%.sol}.json"

    newDirName="${newFileName%/*}"
    "${THE_MKDIR}" -p "${newDirName}"

    abiFileName="artifacts/${contract}/${contract##*/}"
    abiFileName="${abiFileName%.sol}.json"
    if [[ -f "${abiFileName}" ]]; then
        "${THE_CP}" -f "${abiFileName}" "${newDirName}"
    fi
done < <("${THE_FIND}" 'contracts' -type f -iname '*.sol')
