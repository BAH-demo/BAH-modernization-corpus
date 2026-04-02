package com.banking.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Account entity - modernized from COBOL ACCOUNT-RECORD copybook.
 *
 * Original COBOL data structure:
 *   05 ACCOUNT-NUMBER        PIC 9(10).
 *   05 ACCOUNT-TYPE          PIC X(8).
 *   05 ACCOUNT-BALANCE       PIC S9(13)V99 COMP-3.
 *   05 ACCOUNT-INTEREST-RATE PIC 9V9(4) COMP-3.
 *   05 ACCOUNT-OPENED        PIC X(10).
 *   05 ACCOUNT-OVERDRAFT     PIC S9(9)V99 COMP-3.
 *   05 ACCOUNT-LAST-STMT     PIC X(10).
 *   05 ACCOUNT-NEXT-STMT     PIC X(10).
 *   05 ACCOUNT-AVAILABLE     PIC S9(13)V99 COMP-3.
 *   05 ACCOUNT-ACTUAL         PIC S9(13)V99 COMP-3.
 *
 * COMP-3 (packed decimal) fields are mapped to BigDecimal for precision.
 */
@Entity
@Table(name = "accounts")
public class Account {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "account_number", unique = true, nullable = false, length = 10)
    @NotBlank(message = "Account number is required")
    private String accountNumber;

    @Column(name = "customer_number", nullable = false, length = 10)
    @NotBlank(message = "Customer number is required")
    private String customerNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "account_type", nullable = false)
    private AccountType accountType;

    /** Balance - replaces COMP-3 PIC S9(13)V99 */
    @Column(name = "balance", precision = 15, scale = 2, nullable = false)
    private BigDecimal balance = BigDecimal.ZERO;

    @Column(name = "interest_rate", precision = 5, scale = 4)
    private BigDecimal interestRate = BigDecimal.ZERO;

    @Column(name = "overdraft_limit", precision = 11, scale = 2)
    private BigDecimal overdraftLimit = BigDecimal.ZERO;

    @Column(name = "available_balance", precision = 15, scale = 2)
    private BigDecimal availableBalance = BigDecimal.ZERO;

    @Column(name = "opened_date")
    private LocalDateTime openedDate;

    @Column(name = "last_statement_date")
    private LocalDateTime lastStatementDate;

    @Column(name = "status", length = 10)
    @NotBlank
    private String status = "OPEN";

    public Account() {
        this.openedDate = LocalDateTime.now();
    }

    public Account(String accountNumber, String customerNumber, AccountType accountType, BigDecimal balance) {
        this();
        this.accountNumber = accountNumber;
        this.customerNumber = customerNumber;
        this.accountType = accountType;
        this.balance = balance;
        this.availableBalance = balance;
    }

    // Getters and setters

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }

    public String getCustomerNumber() { return customerNumber; }
    public void setCustomerNumber(String customerNumber) { this.customerNumber = customerNumber; }

    public AccountType getAccountType() { return accountType; }
    public void setAccountType(AccountType accountType) { this.accountType = accountType; }

    public BigDecimal getBalance() { return balance; }
    public void setBalance(BigDecimal balance) {
        this.balance = balance;
        updateAvailableBalance();
    }

    public BigDecimal getInterestRate() { return interestRate; }
    public void setInterestRate(BigDecimal interestRate) { this.interestRate = interestRate; }

    public BigDecimal getOverdraftLimit() { return overdraftLimit; }
    public void setOverdraftLimit(BigDecimal overdraftLimit) {
        this.overdraftLimit = overdraftLimit;
        updateAvailableBalance();
    }

    public BigDecimal getAvailableBalance() { return availableBalance; }
    public void setAvailableBalance(BigDecimal availableBalance) { this.availableBalance = availableBalance; }

    public LocalDateTime getOpenedDate() { return openedDate; }
    public void setOpenedDate(LocalDateTime openedDate) { this.openedDate = openedDate; }

    public LocalDateTime getLastStatementDate() { return lastStatementDate; }
    public void setLastStatementDate(LocalDateTime lastStatementDate) { this.lastStatementDate = lastStatementDate; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    private void updateAvailableBalance() {
        if (balance != null && overdraftLimit != null) {
            this.availableBalance = balance.add(overdraftLimit);
        }
    }
}
