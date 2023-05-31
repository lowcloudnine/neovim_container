#!/usr/bin/expect

set cmd getnf
set fonts "13,16,30,51,52"

eval spawn $cmd
expect "3-5):"
send "$fonts\r"
interact
