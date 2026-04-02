package com.banking.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Transaction entity - modernized from COBOL TRANSACTION-RECORD.
 *
 * Original COBOL data structure:
 *   05 TRANSACTION-ID        PIC 9(12).
 *   05 TRANSACTION-ACCT-NO   PIC 9(10).
 *   05 TRANSACTION-TYPE      PIC X(4).
 *       88 TXN-CREDIT        VALUE 'CRDT'.
 *       88 TXN-DEBIT         VALUE 'DBIT'.
 *       88 TXN-TRANSFER      VALUE 'XFER'.
 *   05 TRANSACTION-AMOUNT    PIC S9(13)V99 COMP-3.
 *   05 TRANSACTION-DATE      PIC X(26).
 *   05 TRANSACTION-DESC      PIC X(40).
 *
 * COBOL level-88 condition names are replaced by a Java enum.
 */
@Entity
@Table(name = "transactions")
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "account_number", nullable = false, length = 10)
    private String accountNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false)
    private TransactionType transactionType;

    @Column(name = "amount", precision = 15, scale = 2, nullable = false)
    private BigDecimal amount;

    @Column(name = "transaction_date", nullable = false)
    private LocalDateTime transactionDate;

    @Column(name = "description", length = 40)
    private String description;

    @Column(name = "target_account", length = 10)
    private String targetAccount;

    @Column(name = "balance_after", precision = 15, scale = 2)
    private BigDecimal balanceAfter;

    public Transaction() {
        this.transactionDate = LocalDateTime.now();
    }

    public Transaction(String accountNumber, TransactionType transactionType,
                       BigDecimal amount, String description) {
        this();
        this.accountNumber = accountNumber;
        this.transactionType = transactionType;
        this.amount = amount;
        this.description = description;
    }

    // Getters and setters

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }

    public TransactionType getTransactionType() { return transactionType; }
    public void setTransactionType(TransactionType transactionType) { this.transactionType = transactionType; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public LocalDateTime getTransactionDate() { return transactionDate; }
    public void setTransactionDate(LocalDateTime transactionDate) { this.transactionDate = transactionDate; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getTargetAccount() { return targetAccount; }
    public void setTargetAccount(String targetAccount) { this.targetAccount = targetAccount; }

    public BigDecimal getBalanceAfter() { return balanceAfter; }
    public void setBalanceAfter(BigDecimal balanceAfter) { this.balanceAfter = balanceAfter; }
}
