#!/bin/bash

source "$SRC_HOME/src/shared-functions.sh"
source "$SRC_HOME/.env"

print_guidance() {
	echo 'coinmaster:
    cli > starts sqlite3 shell
    open > opens database in sqlitebrowser
    connect > invoke connection  manager
    transac > invoke transaction manager
    expense > invoke expenses manager
    new transac > inserts a transaction in coinmaster
    dump > dump database'
}

main() {

    case "$1" in

        '') print_guidance ;;
        cli | start) start_sqlite3 ;;
        gui | open) open_sqlitebrowser ;;
        new) shift ; route_new "$@" ;;
        tx | transac*) shift ; "$transactions_manager" "$@" ;;
        xp | *xpen*  ) shift ; "$expenses_manager" "$@" ;;
        dump | backup) dump_database ;;
        *) echo 'nothing happened...' ;;

    esac

}

#FIXME:
dump_database() {
    sqlite3 "$coinmaster_location" <<EOF
.headers on
.output /home/ahmad/data/coin/coinmaster.dump
.dump
EOF

echo "coinmaster.sqlite dumped to /home/ahmad/data/coin/coinmaster.dump (hardcoded because of strange syntax)"

}

open_sqlitebrowser() {
    nohup sqlitebrowser $coinmaster_location 2> /tmp/coinmaster.log &
}

route_new() {
    case "$1" in
        '') echo 'new what?' ;;
        transac*) "$transactions_manager" --new ;;
        *) echo "tf is $@. See $SRC_HOME" ;;
    esac
}

start_sqlite3() {
    sqlite3 "$coinmaster_location" -box "SELECT * FROM _main_"
    echo -e "SELECT FROM THE FOLLOWING:"
    sqlite3 "$coinmaster_location" .tables
    echo ''
    sqlite3 "$coinmaster_location" -box
}
