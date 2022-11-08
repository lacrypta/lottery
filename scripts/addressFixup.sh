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

THE_CUT="$(get_command_or_fail cut)"
THE_GIT="$(get_command_or_fail git)"
THE_GREP="$(get_command_or_fail grep)"
THE_HEAD="$(get_command_or_fail head)"
THE_SED="$(get_command_or_fail sed)"

builtin cd "$("${THE_GIT}" rev-parse --show-toplevel || builtin true)" || exit 1

"${THE_SED}" -i -r "s/https:\/\/polygonscan.com\/address\/0x[0-9a-fA-F]{40}/https:\/\/polygonscan.com\/address\/$("${THE_GREP}" '"address":' deployments/matic/Lottery.json | "${THE_HEAD}" -n1 | "${THE_CUT}" -d\" -f4)/g" README.md
