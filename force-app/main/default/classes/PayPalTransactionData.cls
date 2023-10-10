public class PayPalTransactionData {
	public class Payer_info {
		public String account_id;
		public Address address;
		public String email_address;
		public String address_status;
		public String payer_status;
		public Payer_name payer_name;
		public String country_code;
	}

	public class Shipping_info {
		public String name;
		public Address address;
	}

	public class Transaction_details {
		public Transaction_info transaction_info;
		public Payer_info payer_info;
		public Shipping_info shipping_info;
		public Cart_info cart_info;
		public Store_info store_info;
		public Store_info auction_info;
		public Store_info incentive_info;
	}

    public List<Transaction_details> transaction_details {get; set;}
	public String account_number {get; set;}
	public String last_refreshed_datetime {get; set;}
	public Integer page {get; set;}
	public Integer total_items {get; set;}
	public Integer total_pages {get; set;}
	public List<Links> links {get; set;}
	public Integer page_size {get; set;}
	public String start_datetime {get; set;}
	public String end_datetime {get; set;}
	public Boolean excludeAccountContactProcessing {get; set;}

	public class Address {
		public String line1;
		public String line2;
		public String city;
		public String state;
		public String country_code;
		public String postal_code;
	}

	public class Store_info {
	}

	public class Payer_name {
		public String given_name;
		public String surname;
		public String alternate_full_name;
	}

	public class Cart_info {
		public List<Item_details> item_details;
	}

	public class Tax_amounts {
		public Transaction_amount tax_amount;
	}

	public class Transaction_amount {
		public String currency_code;
		public String value;
	}

	public class Item_details {
		public String item_code;
		public String item_name;
		public String item_description;
		public String item_quantity;
		public Transaction_amount item_unit_price;
		public Transaction_amount item_amount;
		public List<Tax_amounts> tax_amounts;
		public Transaction_amount total_item_amount;
		public String invoice_number;
	}

	public class Transaction_info {
		public String paypal_account_id;
		public String transaction_id;
		public String paypal_reference_id;
		public String paypal_reference_id_type;
		public String transaction_event_code;
		public String transaction_initiation_date;
		public String transaction_updated_date;
		public Transaction_amount transaction_amount;
		public Transaction_amount fee_amount;
		public Transaction_amount insurance_amount;
		public Transaction_amount shipping_amount;
		public Transaction_amount shipping_discount_amount;
		public String transaction_status;
		public String transaction_subject;
		public String transaction_note;
		public String invoice_id;
		public String custom_field;
		public String protection_eligibility;
	}

	public class Links {
		public String href;
		public String rel;
		public String method;
	}
}