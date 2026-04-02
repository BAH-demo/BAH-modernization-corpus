package com.banking.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Customer entity - modernized from COBOL CUSTOMER-RECORD copybook.
 *
 * Original COBOL data structure:
 *   05 CUSTOMER-NUMBER       PIC 9(10).
 *   05 CUSTOMER-NAME         PIC X(60).
 *   05 CUSTOMER-ADDRESS      PIC X(160).
 *   05 CUSTOMER-DOB          PIC X(10).
 *   05 CUSTOMER-CREDIT-SCORE PIC 9(3).
 *   05 CUSTOMER-REVIEW-DATE  PIC X(10).
 */
@Entity
@Table(name = "customers")
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "customer_number", unique = true, nullable = false, length = 10)
    @NotBlank(message = "Customer number is required")
    private String customerNumber;

    @Column(name = "name", nullable = false, length = 60)
    @NotBlank(message = "Customer name is required")
    @Size(max = 60)
    private String name;

    @Column(name = "address", length = 160)
    @Size(max = 160)
    private String address;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    @Column(name = "credit_score")
    @Min(0)
    @Max(999)
    private int creditScore;

    @Column(name = "review_date")
    private LocalDate reviewDate;

    @Column(name = "created_date")
    private LocalDateTime createdDate;

    public Customer() {
        this.createdDate = LocalDateTime.now();
    }

    public Customer(String customerNumber, String name, String address, LocalDate dateOfBirth) {
        this();
        this.customerNumber = customerNumber;
        this.name = name;
        this.address = address;
        this.dateOfBirth = dateOfBirth;
    }

    // Getters and setters

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCustomerNumber() { return customerNumber; }
    public void setCustomerNumber(String customerNumber) { this.customerNumber = customerNumber; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public LocalDate getDateOfBirth() { return dateOfBirth; }
    public void setDateOfBirth(LocalDate dateOfBirth) { this.dateOfBirth = dateOfBirth; }

    public int getCreditScore() { return creditScore; }
    public void setCreditScore(int creditScore) { this.creditScore = creditScore; }

    public LocalDate getReviewDate() { return reviewDate; }
    public void setReviewDate(LocalDate reviewDate) { this.reviewDate = reviewDate; }

    public LocalDateTime getCreatedDate() { return createdDate; }
    public void setCreatedDate(LocalDateTime createdDate) { this.createdDate = createdDate; }
}
