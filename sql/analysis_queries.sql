--Total Tickets
SELECT COUNT(*) AS total_tickets FROM tickets;

--Open Tickets
SELECT COUNT(*) AS open_tickets
FROM tickets
WHERE ticket_status ILIKE 'open';

--Closed Tickets
SELECT COUNT(*) AS closed_tickets
FROM tickets
WHERE ticket_status ILIKE 'closed';

--Tickets by Type (PieChart)
SELECT
    ticket_type,
	COUNT(*) AS ticket_count
FROM tickets
GROUP BY ticket_type
ORDER BY ticket_count DESC;

--Tickets by Priority (BarChart)
SELECT
    ticket_priority,
	COUNT(*) AS ticket_count
FROM tickets
GROUP BY ticket_priority
ORDER BY ticket_count DESC;

--Tickets Created Over Time (LineChart)
SELECT
    date_of_purchase,
	COUNT(*) AS tickets_created
FROM tickets
GROUP BY date_of_purchase
ORDER BY date_of_purchase;

--Average Resolution Time
SELECT
    AVG(EXTRACT(EPOCH FROM time_to_resolution)/3600) AS avg_resolution_hours
FROM tickets
WHERE time_to_resolution IS NOT NULL;

--Average Customer Satisfaction Rating
SELECT
    ROUND(AVG(customer_satisfaction_rating), 2) AS avg_satisfaction
FROM tickets
WHERE customer_satisfaction_rating IS NOT NULL;

--SLA Breaches (Card & Detail)
SELECT
    COUNT(*) AS sla_breaches,
	ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM tickets), 2) AS breach_percentage
FROM tickets
WHERE time_to_resolution > INTERVAL '48 hours';
