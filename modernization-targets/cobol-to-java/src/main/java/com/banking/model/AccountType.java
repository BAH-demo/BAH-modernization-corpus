package com.banking.model;

/**
 * Account types - modernized from COBOL ACCOUNT-TYPE PIC X(8).
 *
 * Original COBOL used string values like 'SAVINGS ', 'CHECKING', 'LOAN    '.
 * Java enum provides type safety and eliminates trailing-space issues.
 */
public enum AccountType {
    SAVINGS("Savings Account"),
    CHECKING("Checking Account"),
    LOAN("Loan Account"),
    MORTGAGE("Mortgage Account"),
    ISA("Individual Savings Account");

    private final String description;

    AccountType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
