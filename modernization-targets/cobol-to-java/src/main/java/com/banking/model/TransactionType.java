package com.banking.model;

/**
 * Transaction types - modernized from COBOL level-88 condition names.
 *
 * Original COBOL:
 *   05 TRANSACTION-TYPE  PIC X(4).
 *       88 TXN-CREDIT    VALUE 'CRDT'.
 *       88 TXN-DEBIT     VALUE 'DBIT'.
 *       88 TXN-TRANSFER  VALUE 'XFER'.
 */
public enum TransactionType {
    CREDIT("CRDT"),
    DEBIT("DBIT"),
    TRANSFER("XFER");

    private final String cobolCode;

    TransactionType(String cobolCode) {
        this.cobolCode = cobolCode;
    }

    public String getCobolCode() {
        return cobolCode;
    }

    public static TransactionType fromCobolCode(String code) {
        for (TransactionType type : values()) {
            if (type.cobolCode.equals(code)) {
                return type;
            }
        }
        throw new IllegalArgumentException("Unknown COBOL transaction code: " + code);
    }
}
