/**
 * A postal address as it crosses the wire today — identical shape independently duplicated
 * in sales-service's OrderAddress and config-service's Address before this schema existed.
 */
export interface Address {
    alias:      string;
    city:       string;
    complement: string;
    district:   string;
    /**
     * Empty when the address is an inline snapshot (e.g. on an order) rather than a saved
     * record.
     */
    id?: string;
    /**
     * Absent (not null) when unset — Go's omitempty drops the key entirely.
     */
    lat?: number;
    /**
     * Absent (not null) when unset — Go's omitempty drops the key entirely.
     */
    lng?:   number;
    number: string;
    state:  string;
    street: string;
    zip:    string;
}

/**
 * A purchasing quote (orçamento), matching purchasing-service's domain.Quote wire shape.
 * QuoteLine is intentionally local to this schema — it is NOT $ref'd to sales-service's
 * OrderItem, which stays a separate, independently-evolving shape per its own bounded
 * context.
 */
export interface Quote {
    /**
     * Server-assigned; absent on a create request.
     */
    created_at?:      string;
    delivery_amount?: number;
    discount_amount?: number;
    /**
     * Server-assigned; absent on a create request.
     */
    id?:     string;
    items:   QuoteLine[];
    notes:   string;
    status?: QuoteStatus;
    /**
     * Server-computed: sum of item totals. Absent/ignored on a create or update request.
     */
    subtotal_amount?: number;
    supplier_id:      string;
    /**
     * Server-computed: subtotal - discount + delivery. Absent/ignored on a create or update
     * request.
     */
    total_amount?: number;
}

export interface QuoteLine {
    /**
     * Server-assigned; absent on a create/update request.
     */
    id?:        string;
    product_id: string;
    quantity:   number;
    /**
     * Server-computed: quantity * unit_price.
     */
    total_price?: number;
    unit_price:   number;
}

/**
 * Server-assigned; absent/ignored on a create or update request.
 */
export enum QuoteStatus {
    Cancelled = "CANCELLED",
    Converted = "CONVERTED",
    Open = "OPEN",
}
