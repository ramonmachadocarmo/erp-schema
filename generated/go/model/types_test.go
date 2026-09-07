package model

import (
	"encoding/json"
	"testing"
	"time"
)

// Round-trip tests for generated (de)serialization — the only thing worth unit-testing
// about codegen'd types is that Marshal/Unmarshal actually agree with each other and with
// the schema's required/optional rules, since a codegen regression here would silently
// break every consumer (Go, TS, Dart) at once.

func TestAddressRoundTrip(t *testing.T) {
	lat := -23.55
	lng := -46.63
	in := Address{
		Alias: "Casa", Zip: "01310-100", Street: "Av. Paulista", Number: "1000",
		Complement: "Apto 1", District: "Bela Vista", City: "São Paulo", State: "SP",
		Lat: &lat, Lng: &lng,
	}
	b, err := json.Marshal(in)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	var out Address
	if err := json.Unmarshal(b, &out); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if out != (Address{}) && (out.Alias != in.Alias || out.Zip != in.Zip || *out.Lat != *in.Lat || *out.Lng != *in.Lng) {
		t.Fatalf("round-trip mismatch: got %+v, want %+v", out, in)
	}
}

func TestAddressMissingRequiredFieldFailsValidation(t *testing.T) {
	full := map[string]any{
		"alias": "a", "zip": "1", "street": "s", "number": "1",
		"complement": "", "district": "d", "city": "c", "state": "SP",
	}
	for _, missing := range []string{"alias", "zip", "street", "number", "complement", "district", "city", "state"} {
		partial := map[string]any{}
		for k, v := range full {
			if k != missing {
				partial[k] = v
			}
		}
		raw, err := json.Marshal(partial)
		if err != nil {
			t.Fatalf("marshal fixture: %v", err)
		}
		var out Address
		if err := json.Unmarshal(raw, &out); err == nil {
			t.Errorf("expected error for missing required field %q, got nil", missing)
		}
	}
}

func TestQuoteRoundTripWithOptionalServerFields(t *testing.T) {
	created := time.Date(2026, 1, 15, 10, 0, 0, 0, time.UTC)
	status := QuoteStatusOPEN
	in := Quote{
		SupplierID: "sup-1",
		Notes:      "urgent",
		Items: []QuoteLine{
			{ProductID: "p1", Quantity: 2, UnitPrice: 9.5},
		},
		Status:    &status,
		CreatedAt: &created,
	}
	b, err := json.Marshal(in)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	var out Quote
	if err := json.Unmarshal(b, &out); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if out.SupplierID != in.SupplierID || out.Notes != in.Notes || len(out.Items) != 1 {
		t.Fatalf("round-trip mismatch: got %+v", out)
	}
	if out.Items[0].ProductID != "p1" || out.Items[0].Quantity != 2 || out.Items[0].UnitPrice != 9.5 {
		t.Fatalf("round-trip item mismatch: got %+v", out.Items[0])
	}
	if out.Status == nil || *out.Status != QuoteStatusOPEN {
		t.Fatalf("round-trip status mismatch: got %+v", out.Status)
	}
}

func TestQuoteCreateRequestOmitsServerComputedFields(t *testing.T) {
	// A create request has no id/status/subtotal/total/created_at — confirms those fields
	// are genuinely optional (omitempty), matching purchasing-service's create contract.
	in := Quote{
		SupplierID: "sup-1",
		Notes:      "",
		Items:      []QuoteLine{{ProductID: "p1", Quantity: 1, UnitPrice: 5}},
	}
	b, err := json.Marshal(in)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	var raw map[string]any
	if err := json.Unmarshal(b, &raw); err != nil {
		t.Fatalf("unmarshal to map: %v", err)
	}
	for _, absent := range []string{"id", "status", "subtotal_amount", "total_amount", "created_at"} {
		if _, ok := raw[absent]; ok {
			t.Errorf("expected %q to be omitted from a create request, but it was present", absent)
		}
	}
}

func TestQuoteMissingRequiredFieldFailsValidation(t *testing.T) {
	cases := map[string]string{
		"supplier_id": `{"notes":"x","items":[]}`,
		"notes":       `{"supplier_id":"s","items":[]}`,
		"items":       `{"supplier_id":"s","notes":"x"}`,
	}
	for field, raw := range cases {
		var out Quote
		if err := json.Unmarshal([]byte(raw), &out); err == nil {
			t.Errorf("expected error for missing required field %q, got nil", field)
		}
	}
}

func TestQuoteLineMissingRequiredFieldFailsValidation(t *testing.T) {
	cases := map[string]string{
		"product_id": `{"quantity":1,"unit_price":1}`,
		"quantity":   `{"product_id":"p","unit_price":1}`,
		"unit_price": `{"product_id":"p","quantity":1}`,
	}
	for field, raw := range cases {
		var out QuoteLine
		if err := json.Unmarshal([]byte(raw), &out); err == nil {
			t.Errorf("expected error for missing required field %q, got nil", field)
		}
	}
}

func TestQuoteStatusRejectsInvalidValue(t *testing.T) {
	var s QuoteStatus
	if err := json.Unmarshal([]byte(`"NOT_A_REAL_STATUS"`), &s); err == nil {
		t.Fatal("expected error for invalid QuoteStatus value, got nil")
	}
}

func TestQuoteStatusAcceptsEveryDeclaredValue(t *testing.T) {
	for _, v := range []QuoteStatus{QuoteStatusOPEN, QuoteStatusCONVERTED, QuoteStatusCANCELLED} {
		var s QuoteStatus
		b, _ := json.Marshal(v)
		if err := json.Unmarshal(b, &s); err != nil {
			t.Errorf("value %q should be valid: %v", v, err)
		}
	}
}

func TestMalformedJSONFailsToUnmarshal(t *testing.T) {
	for name, target := range map[string]json.Unmarshaler{
		"Address":   &Address{},
		"Quote":     &Quote{},
		"QuoteLine": &QuoteLine{},
	} {
		if err := target.UnmarshalJSON([]byte(`{not valid json`)); err == nil {
			t.Errorf("%s: expected error for malformed JSON, got nil", name)
		}
	}
}
