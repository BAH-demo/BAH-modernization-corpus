package com.banking.service;

import com.banking.model.Customer;
import com.banking.repository.CustomerRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

/**
 * Customer service - translates COBOL customer management paragraphs.
 *
 * Maps CICS transactions:
 *   CUST (Customer Create)  -> createCustomer()
 *   CUPU (Customer Update)  -> updateCustomer()
 *   CUGT (Customer Get)     -> getCustomer()
 */
@Service
@Transactional
public class CustomerService {

    private final CustomerRepository customerRepository;

    public CustomerService(CustomerRepository customerRepository) {
        this.customerRepository = customerRepository;
    }

    public Customer createCustomer(String name, String address, LocalDate dateOfBirth) {
        String customerNumber = generateCustomerNumber();
        Customer customer = new Customer(customerNumber, name, address, dateOfBirth);
        return customerRepository.save(customer);
    }

    @Transactional(readOnly = true)
    public Customer getCustomer(String customerNumber) {
        return customerRepository.findByCustomerNumber(customerNumber)
                .orElseThrow(() -> new CustomerNotFoundException(
                        "Customer not found: " + customerNumber));
    }

    public Customer updateCustomer(String customerNumber, String name,
                                   String address, int creditScore) {
        Customer customer = getCustomer(customerNumber);
        if (name != null) customer.setName(name);
        if (address != null) customer.setAddress(address);
        if (creditScore >= 0) customer.setCreditScore(creditScore);
        customer.setReviewDate(LocalDate.now());
        return customerRepository.save(customer);
    }

    @Transactional(readOnly = true)
    public List<Customer> getAllCustomers() {
        return customerRepository.findAll();
    }

    private String generateCustomerNumber() {
        long count = customerRepository.count() + 1;
        return String.format("%010d", 20000 + count);
    }

    public static class CustomerNotFoundException extends RuntimeException {
        public CustomerNotFoundException(String message) { super(message); }
    }
}
