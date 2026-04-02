package com.banking.repository;

import com.banking.model.Account;
import com.banking.model.AccountType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Account repository - replaces VSAM KSDS file I/O operations.
 *
 * Original COBOL access patterns:
 *   READ ACCOUNT-FILE INTO WS-ACCOUNT-RECORD KEY IS WS-ACCOUNT-NUMBER
 *   WRITE ACCOUNT-RECORD FROM WS-ACCOUNT-RECORD
 *   REWRITE ACCOUNT-RECORD FROM WS-ACCOUNT-RECORD
 *   DELETE ACCOUNT-FILE RECORD KEY IS WS-ACCOUNT-NUMBER
 *
 * JPA provides equivalent operations through repository methods.
 */
@Repository
public interface AccountRepository extends JpaRepository<Account, Long> {

    Optional<Account> findByAccountNumber(String accountNumber);

    List<Account> findByCustomerNumber(String customerNumber);

    List<Account> findByAccountType(AccountType accountType);

    List<Account> findByStatus(String status);

    @Query("SELECT COUNT(a) FROM Account a WHERE a.customerNumber = :customerNumber")
    long countByCustomerNumber(String customerNumber);

    boolean existsByAccountNumber(String accountNumber);
}
