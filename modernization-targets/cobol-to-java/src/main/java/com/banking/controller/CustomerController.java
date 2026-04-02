package com.banking.controller;

import com.banking.model.Customer;
import com.banking.service.CustomerService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Customer REST controller - replaces CICS CUST/CUPU/CUGT transactions.
 */
@RestController
@RequestMapping("/api/customers")
public class CustomerController {

    private final CustomerService customerService;

    public CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    @PostMapping
    public ResponseEntity<Customer> createCustomer(
            @RequestBody CreateCustomerRequest request) {
        Customer customer = customerService.createCustomer(
                request.name(), request.address(), request.dateOfBirth());
        return ResponseEntity.status(HttpStatus.CREATED).body(customer);
    }

    @GetMapping("/{customerNumber}")
    public ResponseEntity<Customer> getCustomer(
            @PathVariable String customerNumber) {
        return ResponseEntity.ok(customerService.getCustomer(customerNumber));
    }

    @PutMapping("/{customerNumber}")
    public ResponseEntity<Customer> updateCustomer(
            @PathVariable String customerNumber,
            @RequestBody UpdateCustomerRequest request) {
        Customer customer = customerService.updateCustomer(
                customerNumber, request.name(), request.address(), request.creditScore());
        return ResponseEntity.ok(customer);
    }

    @GetMapping
    public ResponseEntity<List<Customer>> getAllCustomers() {
        return ResponseEntity.ok(customerService.getAllCustomers());
    }

    @ExceptionHandler(CustomerService.CustomerNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleNotFound(
            CustomerService.CustomerNotFoundException e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("status", "ERROR", "message", e.getMessage()));
    }

    public record CreateCustomerRequest(
            String name, String address, LocalDate dateOfBirth) {}

    public record UpdateCustomerRequest(
            String name, String address, int creditScore) {}
}
