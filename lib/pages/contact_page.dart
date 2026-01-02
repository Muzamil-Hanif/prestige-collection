import 'package:flutter/material.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Icon(
                Icons.contact_mail,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Get in Touch',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We\'d love to hear from you',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildContactCard(
              context,
              Icons.email,
              'Email',
              'support@mensluxurystore.com',
              'Send us an email',
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              context,
              Icons.phone,
              'Phone',
              '+1 (555) 123-4567',
              'Call us during business hours',
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              context,
              Icons.location_on,
              'Address',
              '123 Luxury Street\nNew York, NY 10001',
              'Visit our store',
            ),
            const SizedBox(height: 32),
            Text(
              'Business Hours',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHoursRow('Monday - Friday', '9:00 AM - 6:00 PM'),
                    const Divider(),
                    _buildHoursRow('Saturday', '10:00 AM - 4:00 PM'),
                    const Divider(),
                    _buildHoursRow('Sunday', 'Closed'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Send us a Message',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Your Email',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Message',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message sent successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Send Message',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    IconData icon,
    String title,
    String info,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(info),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening $title'),
                duration: const Duration(seconds: 3),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            hours,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

