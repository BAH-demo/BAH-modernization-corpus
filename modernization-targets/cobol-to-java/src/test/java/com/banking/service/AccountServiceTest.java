package com.banking.service;

import com.banking.model.*;
import com.banking.repository.AccountRepository;
import com.banking.repository.TransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * JUnit 5 tests for AccountService.
 * Tests core banking transactions that map to COBOL CICS operations.
 */
@SpringBootTest
@Transactional
class AccountServiceTest {

    @Autowired
    private AccountService accountService;

    @Autowired
    private AccountRepository accountRepository;

    @Autowired
    private TransactionRepository transactionRepository;

    @Nested
    @DisplayName("Account Creation (CICS: ACCT)")
    class AccountCreationTests {

        @Test
        @DisplayName("Should create savings account with initial deposit")
        void createSavingsAccount() {
            Account account = accountService.createAccount(
                    "CUST001", AccountType.SAVINGS, new BigDecimal("1000.00"));

            assertNotNull(account.getId());
            assertNotNull(account.getAccountNumber());
            assertEquals(AccountType.SAVINGS, account.getAccountType());
            assertEquals(new BigDecimal("1000.00"), account.getBalance());
            assertEquals("CUST001", account.getCustomerNumber());
            assertEquals("OPEN", account.getStatus());
        }

        @Test
        @DisplayName("Should create checking account with zero balance")
        void createCheckingAccountZeroBalance() {
            Account account = accountService.createAccount(
                    "CUST002", AccountType.CHECKING, BigDecimal.ZERO);

            assertNotNull(account.getId());
            assertEquals(AccountType.CHECKING, account.getAccountType());
            assertEquals(BigDecimal.ZERO, account.getBalance());
        }

        @Test
        @DisplayName("Should reject negative initial deposit")
        void rejectNegativeDeposit() {
            assertThrows(IllegalArgumentException.class, () ->
                    accountService.createAccount(
                            "CUST003", AccountType.SAVINGS, new BigDecimal("-100.00")));
        }

        @Test
        @DisplayName("Should record initial deposit transaction")
        void recordInitialDepositTransaction() {
            Account account = accountService.createAccount(
                    "CUST004", AccountType.SAVINGS, new BigDecimal("500.00"));

            List<Transaction> txns = transactionRepository
                    .findByAccountNumberOrderByTransactionDateDesc(account.getAccountNumber());
            assertEquals(1, txns.size());
            assertEquals(TransactionType.CREDIT, txns.get(0).getTransactionType());
            assertEquals(new BigDecimal("500.00"), txns.get(0).getAmount());
        }
    }

    @Nested
    @DisplayName("Balance Inquiry (CICS: BALN)")
    class BalanceInquiryTests {

        @Test
        @DisplayName("Should return correct balance")
        void getBalance() {
            Account account = accountService.createAccount(
                    "CUST010", AccountType.SAVINGS, new BigDecimal("2500.00"));

            BigDecimal balance = accountService.getBalance(account.getAccountNumber());
            assertEquals(new BigDecimal("2500.00"), balance);
        }

        @Test
        @DisplayName("Should throw for non-existent account")
        void balanceNotFound() {
            assertThrows(AccountService.AccountNotFoundException.class, () ->
                    accountService.getBalance("9999999999"));
        }
    }

    @Nested
    @DisplayName("Fund Transfer (CICS: XFER)")
    class TransferTests {

        private Account sourceAccount;
        private Account targetAccount;

        @BeforeEach
        void setUp() {
            sourceAccount = accountService.createAccount(
                    "CUST020", AccountType.CHECKING, new BigDecimal("5000.00"));
            targetAccount = accountService.createAccount(
                    "CUST021", AccountType.SAVINGS, new BigDecimal("1000.00"));
        }

        @Test
        @DisplayName("Should transfer funds between accounts")
        void successfulTransfer() {
            AccountService.TransferResult result = accountService.transfer(
                    sourceAccount.getAccountNumber(),
                    targetAccount.getAccountNumber(),
                    new BigDecimal("1500.00"));

            assertEquals(new BigDecimal("3500.00"), result.fromBalance());
            assertEquals(new BigDecimal("2500.00"), result.toBalance());
        }

        @Test
        @DisplayName("Should reject transfer exceeding balance")
        void insufficientFundsTransfer() {
            assertThrows(AccountService.InsufficientFundsException.class, () ->
                    accountService.transfer(
                            sourceAccount.getAccountNumber(),
                            targetAccount.getAccountNumber(),
                            new BigDecimal("999999.00")));
        }

        @Test
        @DisplayName("Should reject self-transfer")
        void selfTransfer() {
            assertThrows(IllegalArgumentException.class, () ->
                    accountService.transfer(
                            sourceAccount.getAccountNumber(),
                            sourceAccount.getAccountNumber(),
                            new BigDecimal("100.00")));
        }

        @Test
        @DisplayName("Should record transfer transactions on both accounts")
        void transferRecordsTransactions() {
            accountService.transfer(
                    sourceAccount.getAccountNumber(),
                    targetAccount.getAccountNumber(),
                    new BigDecimal("250.00"));

            List<Transaction> sourceTxns = transactionRepository
                    .findByAccountNumberOrderByTransactionDateDesc(
                            sourceAccount.getAccountNumber());
            List<Transaction> targetTxns = transactionRepository
                    .findByAccountNumberOrderByTransactionDateDesc(
                            targetAccount.getAccountNumber());

            // Source has initial deposit + transfer
            assertEquals(2, sourceTxns.size());
            assertEquals(TransactionType.TRANSFER, sourceTxns.get(0).getTransactionType());

            // Target has initial deposit + transfer
            assertEquals(2, targetTxns.size());
            assertEquals(TransactionType.TRANSFER, targetTxns.get(0).getTransactionType());
        }

        @Test
        @DisplayName("Should handle exact balance transfer")
        void exactBalanceTransfer() {
            AccountService.TransferResult result = accountService.transfer(
                    sourceAccount.getAccountNumber(),
                    targetAccount.getAccountNumber(),
                    new BigDecimal("5000.00"));

            assertEquals(BigDecimal.ZERO.setScale(2), result.fromBalance().setScale(2));
            assertEquals(new BigDecimal("6000.00"), result.toBalance());
        }
    }

    @Nested
    @DisplayName("Credit/Debit Operations")
    class CreditDebitTests {

        private Account account;

        @BeforeEach
        void setUp() {
            account = accountService.createAccount(
                    "CUST030", AccountType.SAVINGS, new BigDecimal("1000.00"));
        }

        @Test
        @DisplayName("Should credit funds to account")
        void creditFunds() {
            Account updated = accountService.credit(
                    account.getAccountNumber(), new BigDecimal("500.00"));
            assertEquals(new BigDecimal("1500.00"), updated.getBalance());
        }

        @Test
        @DisplayName("Should debit funds from account")
        void debitFunds() {
            Account updated = accountService.debit(
                    account.getAccountNumber(), new BigDecimal("300.00"));
            assertEquals(new BigDecimal("700.00"), updated.getBalance());
        }

        @Test
        @DisplayName("Should reject debit exceeding balance")
        void debitExceedingBalance() {
            assertThrows(AccountService.InsufficientFundsException.class, () ->
                    accountService.debit(
                            account.getAccountNumber(), new BigDecimal("2000.00")));
        }

        @Test
        @DisplayName("Should reject zero amount")
        void rejectZeroAmount() {
            assertThrows(IllegalArgumentException.class, () ->
                    accountService.credit(account.getAccountNumber(), BigDecimal.ZERO));
        }

        @Test
        @DisplayName("Should reject negative amount")
        void rejectNegativeAmount() {
            assertThrows(IllegalArgumentException.class, () ->
                    accountService.debit(
                            account.getAccountNumber(), new BigDecimal("-50.00")));
        }
    }

    @Nested
    @DisplayName("BCD Arithmetic Edge Cases (COBOL COMP-3)")
    class BcdArithmeticTests {

        @Test
        @DisplayName("Should handle precise decimal arithmetic")
        void preciseDecimalArithmetic() {
            Account account = accountService.createAccount(
                    "CUST040", AccountType.SAVINGS, new BigDecimal("100.10"));

            accountService.credit(account.getAccountNumber(), new BigDecimal("200.20"));
            BigDecimal balance = accountService.getBalance(account.getAccountNumber());
            assertEquals(new BigDecimal("300.30"), balance);
        }

        @Test
        @DisplayName("Should handle large amounts (COMP-3 S9(13)V99)")
        void largeAmounts() {
            Account account = accountService.createAccount(
                    "CUST041", AccountType.SAVINGS, new BigDecimal("9999999999999.99"));

            BigDecimal balance = accountService.getBalance(account.getAccountNumber());
            assertEquals(new BigDecimal("9999999999999.99"), balance);
        }

        @Test
        @DisplayName("Should handle penny amounts correctly")
        void pennyAmounts() {
            Account account = accountService.createAccount(
                    "CUST042", AccountType.SAVINGS, new BigDecimal("0.01"));

            accountService.credit(account.getAccountNumber(), new BigDecimal("0.01"));
            accountService.credit(account.getAccountNumber(), new BigDecimal("0.01"));

            BigDecimal balance = accountService.getBalance(account.getAccountNumber());
            assertEquals(new BigDecimal("0.03"), balance);
        }

        @Test
        @DisplayName("Should maintain precision through multiple operations")
        void multipleOperationsPrecision() {
            Account account = accountService.createAccount(
                    "CUST043", AccountType.CHECKING, new BigDecimal("1000.00"));

            // Simulate many small transactions
            for (int i = 0; i < 10; i++) {
                accountService.credit(account.getAccountNumber(), new BigDecimal("33.33"));
            }

            BigDecimal balance = accountService.getBalance(account.getAccountNumber());
            assertEquals(new BigDecimal("1333.30"), balance);
        }
    }

    @Nested
    @DisplayName("Error Handling")
    class ErrorHandlingTests {

        @Test
        @DisplayName("Should handle account not found gracefully")
        void accountNotFound() {
            AccountService.AccountNotFoundException e = assertThrows(
                    AccountService.AccountNotFoundException.class,
                    () -> accountService.getAccount("NONEXISTENT"));
            assertTrue(e.getMessage().contains("NONEXISTENT"));
        }

        @Test
        @DisplayName("Should provide meaningful insufficient funds message")
        void insufficientFundsMessage() {
            Account account = accountService.createAccount(
                    "CUST050", AccountType.SAVINGS, new BigDecimal("100.00"));

            AccountService.InsufficientFundsException e = assertThrows(
                    AccountService.InsufficientFundsException.class,
                    () -> accountService.debit(
                            account.getAccountNumber(), new BigDecimal("500.00")));
            assertTrue(e.getMessage().contains("Insufficient funds"));
        }
    }
}
