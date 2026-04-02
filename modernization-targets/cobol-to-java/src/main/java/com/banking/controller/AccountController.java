package com.banking.controller;

import com.banking.model.*;
import com.banking.service.AccountService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Account REST controller - replaces CICS transaction routing.
 *
 * CICS Transaction ID to REST endpoint mapping:
 *   ACCT -> POST /api/accounts
 *   BALN -> GET  /api/accounts/{accountNumber}/balance
 *   XFER -> POST /api/accounts/transfer
 *   CRDT -> POST /api/accounts/{accountNumber}/credit
 *   DBIT -> POST /api/accounts/{accountNumber}/debit
 *
 * Original CICS used BMS (Basic Mapping Support) screens for I/O.
 * REST API replaces the terminal-based interaction model.
 */
@RestController
@RequestMapping("/api/accounts")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> createAccount(
            @RequestBody CreateAccountRequest request) {
        Account account = accountService.createAccount(
                request.customerNumber(),
                request.accountType(),
                request.initialDeposit());

        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "status", "SUCCESS",
                "accountNumber", account.getAccountNumber(),
                "accountType", account.getAccountType().name(),
                "balance", account.getBalance()
        ));
    }

    @GetMapping("/{accountNumber}")
    public ResponseEntity<Account> getAccount(@PathVariable String accountNumber) {
        Account account = accountService.getAccount(accountNumber);
        return ResponseEntity.ok(account);
    }

    @GetMapping("/{accountNumber}/balance")
    public ResponseEntity<Map<String, Object>> getBalance(
            @PathVariable String accountNumber) {
        BigDecimal balance = accountService.getBalance(accountNumber);
        return ResponseEntity.ok(Map.of(
                "status", "SUCCESS",
                "accountNumber", accountNumber,
                "balance", balance
        ));
    }

    @PostMapping("/{accountNumber}/credit")
    public ResponseEntity<Map<String, Object>> credit(
            @PathVariable String accountNumber,
            @RequestBody AmountRequest request) {
        Account account = accountService.credit(accountNumber, request.amount());
        return ResponseEntity.ok(Map.of(
                "status", "SUCCESS",
                "balance", account.getBalance()
        ));
    }

    @PostMapping("/{accountNumber}/debit")
    public ResponseEntity<Map<String, Object>> debit(
            @PathVariable String accountNumber,
            @RequestBody AmountRequest request) {
        Account account = accountService.debit(accountNumber, request.amount());
        return ResponseEntity.ok(Map.of(
                "status", "SUCCESS",
                "balance", account.getBalance()
        ));
    }

    @PostMapping("/transfer")
    public ResponseEntity<Map<String, Object>> transfer(
            @RequestBody TransferRequest request) {
        AccountService.TransferResult result = accountService.transfer(
                request.fromAccount(),
                request.toAccount(),
                request.amount());
        return ResponseEntity.ok(Map.of(
                "status", "SUCCESS",
                "fromBalance", result.fromBalance(),
                "toBalance", result.toBalance()
        ));
    }

    @GetMapping("/{accountNumber}/transactions")
    public ResponseEntity<List<Transaction>> getTransactions(
            @PathVariable String accountNumber) {
        return ResponseEntity.ok(
                accountService.getTransactionHistory(accountNumber));
    }

    @GetMapping("/customer/{customerNumber}")
    public ResponseEntity<List<Account>> getAccountsByCustomer(
            @PathVariable String customerNumber) {
        return ResponseEntity.ok(
                accountService.getAccountsByCustomer(customerNumber));
    }

    @ExceptionHandler(AccountService.AccountNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleNotFound(
            AccountService.AccountNotFoundException e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("status", "ERROR", "message", e.getMessage()));
    }

    @ExceptionHandler(AccountService.InsufficientFundsException.class)
    public ResponseEntity<Map<String, String>> handleInsufficientFunds(
            AccountService.InsufficientFundsException e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("status", "INSUFFICIENT_FUNDS", "message", e.getMessage()));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> handleBadRequest(
            IllegalArgumentException e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("status", "ERROR", "message", e.getMessage()));
    }

    // Request DTOs
    public record CreateAccountRequest(
            String customerNumber,
            AccountType accountType,
            BigDecimal initialDeposit) {}

    public record AmountRequest(BigDecimal amount) {}

    public record TransferRequest(
            String fromAccount,
            String toAccount,
            BigDecimal amount) {}
}
