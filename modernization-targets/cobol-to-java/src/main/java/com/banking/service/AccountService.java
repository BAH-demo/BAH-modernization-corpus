package com.banking.service;

import com.banking.model.*;
import com.banking.repository.AccountRepository;
import com.banking.repository.TransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Optional;

/**
 * Account service - translates COBOL paragraph logic for account operations.
 *
 * Maps CICS transaction IDs to service methods:
 *   ACCT (Account Creation)  -> createAccount()
 *   BALN (Balance Inquiry)   -> getBalance()
 *   XFER (Fund Transfer)     -> transfer()
 *   UPDH (Account Update)    -> updateAccount()
 *
 * Original COBOL paragraphs like:
 *   CREATE-ACCOUNT-PARAGRAPH
 *   GET-BALANCE-PARAGRAPH
 *   PROCESS-TRANSFER-PARAGRAPH
 * are implemented as Java service methods with proper transaction management.
 */
@Service
@Transactional
public class AccountService {

    private final AccountRepository accountRepository;
    private final TransactionRepository transactionRepository;

    public AccountService(AccountRepository accountRepository,
                          TransactionRepository transactionRepository) {
        this.accountRepository = accountRepository;
        this.transactionRepository = transactionRepository;
    }

    /**
     * Create a new account.
     * Replaces COBOL CREATE-ACCOUNT-PARAGRAPH:
     *   MOVE WS-ACCT-NO TO ACCOUNT-NUMBER
     *   MOVE WS-CUST-NO TO CUSTOMER-NUMBER
     *   MOVE WS-ACCT-TYPE TO ACCOUNT-TYPE
     *   MOVE WS-INIT-BAL TO ACCOUNT-BALANCE
     *   WRITE ACCOUNT-RECORD FROM WS-ACCOUNT-RECORD
     */
    public Account createAccount(String customerNumber, AccountType accountType,
                                 BigDecimal initialDeposit) {
        if (initialDeposit.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Initial deposit cannot be negative");
        }

        String accountNumber = generateAccountNumber();

        Account account = new Account(accountNumber, customerNumber, accountType, initialDeposit);
        account = accountRepository.save(account);

        if (initialDeposit.compareTo(BigDecimal.ZERO) > 0) {
            Transaction txn = new Transaction(
                    accountNumber, TransactionType.CREDIT, initialDeposit, "Initial deposit");
            txn.setBalanceAfter(initialDeposit);
            transactionRepository.save(txn);
        }

        return account;
    }

    /**
     * Get account balance.
     * Replaces COBOL GET-BALANCE-PARAGRAPH:
     *   READ ACCOUNT-FILE INTO WS-ACCOUNT-RECORD KEY IS WS-ACCOUNT-NUMBER
     *   IF FILE-STATUS = '00'
     *     MOVE ACCOUNT-BALANCE TO WS-DISPLAY-BALANCE
     *   ELSE
     *     MOVE 'ACCOUNT NOT FOUND' TO WS-ERROR-MSG
     *   END-IF
     */
    @Transactional(readOnly = true)
    public BigDecimal getBalance(String accountNumber) {
        Account account = accountRepository.findByAccountNumber(accountNumber)
                .orElseThrow(() -> new AccountNotFoundException(
                        "Account not found: " + accountNumber));
        return account.getBalance();
    }

    /**
     * Get account details.
     */
    @Transactional(readOnly = true)
    public Account getAccount(String accountNumber) {
        return accountRepository.findByAccountNumber(accountNumber)
                .orElseThrow(() -> new AccountNotFoundException(
                        "Account not found: " + accountNumber));
    }

    /**
     * Get all accounts for a customer.
     */
    @Transactional(readOnly = true)
    public List<Account> getAccountsByCustomer(String customerNumber) {
        return accountRepository.findByCustomerNumber(customerNumber);
    }

    /**
     * Credit (deposit) funds.
     * Replaces COBOL PROCESS-CREDIT-PARAGRAPH:
     *   ADD WS-AMOUNT TO ACCOUNT-BALANCE
     *   REWRITE ACCOUNT-RECORD FROM WS-ACCOUNT-RECORD
     */
    public Account credit(String accountNumber, BigDecimal amount) {
        validateAmount(amount);

        Account account = getAccount(accountNumber);
        account.setBalance(account.getBalance().add(amount));
        account = accountRepository.save(account);

        Transaction txn = new Transaction(
                accountNumber, TransactionType.CREDIT, amount, "Credit");
        txn.setBalanceAfter(account.getBalance());
        transactionRepository.save(txn);

        return account;
    }

    /**
     * Debit (withdrawal) funds.
     * Replaces COBOL PROCESS-DEBIT-PARAGRAPH:
     *   IF WS-AMOUNT > ACCOUNT-BALANCE
     *     MOVE 'INSUFFICIENT FUNDS' TO WS-ERROR-MSG
     *   ELSE
     *     SUBTRACT WS-AMOUNT FROM ACCOUNT-BALANCE
     *     REWRITE ACCOUNT-RECORD FROM WS-ACCOUNT-RECORD
     *   END-IF
     */
    public Account debit(String accountNumber, BigDecimal amount) {
        validateAmount(amount);

        Account account = getAccount(accountNumber);

        if (amount.compareTo(account.getAvailableBalance()) > 0) {
            throw new InsufficientFundsException(
                    "Insufficient funds. Available: " + account.getAvailableBalance()
                            + ", Requested: " + amount);
        }

        account.setBalance(account.getBalance().subtract(amount));
        account = accountRepository.save(account);

        Transaction txn = new Transaction(
                accountNumber, TransactionType.DEBIT, amount, "Debit");
        txn.setBalanceAfter(account.getBalance());
        transactionRepository.save(txn);

        return account;
    }

    /**
     * Transfer funds between accounts.
     * Replaces COBOL PROCESS-TRANSFER-PARAGRAPH:
     *   PERFORM GET-SOURCE-ACCOUNT
     *   PERFORM GET-TARGET-ACCOUNT
     *   IF WS-AMOUNT > SOURCE-ACCOUNT-BALANCE
     *     MOVE 'INSUFFICIENT FUNDS' TO WS-ERROR-MSG
     *   ELSE
     *     SUBTRACT WS-AMOUNT FROM SOURCE-ACCOUNT-BALANCE
     *     ADD WS-AMOUNT TO TARGET-ACCOUNT-BALANCE
     *     REWRITE SOURCE-ACCOUNT-RECORD
     *     REWRITE TARGET-ACCOUNT-RECORD
     *     PERFORM WRITE-TRANSACTION-RECORD
     *   END-IF
     *
     * @Transactional ensures atomicity (CICS used SYNCPOINT for this).
     */
    public TransferResult transfer(String fromAccountNumber, String toAccountNumber,
                                   BigDecimal amount) {
        validateAmount(amount);

        if (fromAccountNumber.equals(toAccountNumber)) {
            throw new IllegalArgumentException("Cannot transfer to the same account");
        }

        Account fromAccount = getAccount(fromAccountNumber);
        Account toAccount = getAccount(toAccountNumber);

        if (amount.compareTo(fromAccount.getAvailableBalance()) > 0) {
            throw new InsufficientFundsException(
                    "Insufficient funds for transfer. Available: "
                            + fromAccount.getAvailableBalance());
        }

        fromAccount.setBalance(fromAccount.getBalance().subtract(amount));
        toAccount.setBalance(toAccount.getBalance().add(amount));

        accountRepository.save(fromAccount);
        accountRepository.save(toAccount);

        // Record transactions for both accounts
        Transaction debitTxn = new Transaction(
                fromAccountNumber, TransactionType.TRANSFER, amount,
                "Transfer to " + toAccountNumber);
        debitTxn.setTargetAccount(toAccountNumber);
        debitTxn.setBalanceAfter(fromAccount.getBalance());
        transactionRepository.save(debitTxn);

        Transaction creditTxn = new Transaction(
                toAccountNumber, TransactionType.TRANSFER, amount,
                "Transfer from " + fromAccountNumber);
        creditTxn.setTargetAccount(fromAccountNumber);
        creditTxn.setBalanceAfter(toAccount.getBalance());
        transactionRepository.save(creditTxn);

        return new TransferResult(fromAccount.getBalance(), toAccount.getBalance());
    }

    /**
     * Get transaction history for an account.
     */
    @Transactional(readOnly = true)
    public List<Transaction> getTransactionHistory(String accountNumber) {
        // Verify account exists
        getAccount(accountNumber);
        return transactionRepository
                .findByAccountNumberOrderByTransactionDateDesc(accountNumber);
    }

    private void validateAmount(BigDecimal amount) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Amount must be positive");
        }
    }

    private String generateAccountNumber() {
        long count = accountRepository.count() + 1;
        return String.format("%010d", 10000 + count);
    }

    /** Transfer result holding both updated balances. */
    public record TransferResult(BigDecimal fromBalance, BigDecimal toBalance) {}

    /** Exception for account not found - replaces COBOL FILE STATUS '23'. */
    public static class AccountNotFoundException extends RuntimeException {
        public AccountNotFoundException(String message) { super(message); }
    }

    /** Exception for insufficient funds - replaces COBOL ABEND handling. */
    public static class InsufficientFundsException extends RuntimeException {
        public InsufficientFundsException(String message) { super(message); }
    }
}
