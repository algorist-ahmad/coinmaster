#!/bin/bash

# collect user input and return YAML

launch_transaction_form() {
    if recurring_bill
        then echo "START RECURRING BILL FORM"
        else echo "START ONE TIME TRANSAC"
    fi
}

recurring_bill() { gum confirm "Is this a recurring bill?" ; } 
