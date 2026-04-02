package com.banking.repository;

import com.banking.model.Transaction;
import com.banking.model.TransactionType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Transaction repository - replaces VSAM ESDS sequential file I/O.
 *
 * Original COBOL wrote transaction records sequentially to an ESDS file.
 * JPA provides indexed access by account number and date range.
 */
@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {

    List<Transaction> findByAccountNumberOrderByTransactionDateDesc(String accountNumber);

    List<Transaction> findByAccountNumberAndTransactionDateBetween(
            String accountNumber, LocalDateTime start, LocalDateTime end);

    List<Transaction> findByTransactionType(TransactionType type);
}
