INSERT INTO customers (customer_name, customer_email, customer_age, customer_gender)
SELECT DISTINCT ON (customer_email)
    customer_name,
	customer_email,
	customer_age,
	customer_gender
FROM tickets_flat
WHERE customer_email IS NOT NULL;

INSERT INTO products (product_name)
SELECT DISTINCT product_purchased AS product_name
FROM tickets_flat
WHERE product_purchased IS NOT NULL;

INSERT INTO tickets (
    ticket_id,
	customer_id,
	product_id,
	date_of_purchase,
	ticket_type,
	ticket_subject,
	ticket_description,
	ticket_status,
	resolution,
	ticket_priority,
	ticket_channel,
	first_response_time,
	time_to_resolution,
	customer_satisfaction_rating
)
SELECT 
    tf.ticket_id,
	c.customer_id,
	p.product_id,
	tf.date_of_purchase,
	tf.ticket_type,
	tf.ticket_subject,
	tf.ticket_description,
	tf.ticket_status,
	tf.resolution,
	tf.ticket_priority,
	tf.ticket_channel,
	(tf.first_response_time::numeric / 1000000000.0 * INTERVAL '1 second',
	(tf.time_to_resolution::numeric / 1000000000.0 * INTERVAL '1 second',
	tf.customer_satisfaction_rating
FROM tickets_flat tf
JOIN customers c ON c.customer_email = tf.customer_email
JOIN products p ON p.product_name = tf.product_purchased;