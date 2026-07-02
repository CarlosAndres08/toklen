import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onTap;
  final VoidCallback? onSuspend;
  final VoidCallback? onUnsuspend;

  const UserCard({
    required this.user,
    this.onTap,
    this.onSuspend,
    this.onUnsuspend,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final name = _getName();
    final email = _getEmail();
    final role = _getRole();
    final isSuspended = user['is_suspended'] == true;
    final isVerified = user['is_verified'] == true;
    final isActive = user['is_active'] != false;

    Color roleColor;
    String roleLabel;
    switch (role) {
      case 'admin':
        roleColor = Colors.red;
        roleLabel = 'ADMIN';
        break;
      case 'provider':
        roleColor = Colors.blue;
        roleLabel = 'PROVEEDOR';
        break;
      default:
        roleColor = Colors.green;
        roleLabel = 'CLIENTE';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSuspended
            ? const BorderSide(color: Colors.orange, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _avatarColor(role),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.verified,
                                size: 16, color: Colors.blue),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            roleLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: roleColor,
                            ),
                          ),
                        ),
                        if (isSuspended) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SUSPENDIDO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                        if (!isActive && !isSuspended) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'INACTIVO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (onUnsuspend != null)
                IconButton(
                  onPressed: onUnsuspend,
                  icon: const Icon(Icons.unpublished,
                      color: Colors.orange),
                  tooltip: 'Reactivar',
                ),
              if (onSuspend != null && role != 'admin')
                IconButton(
                  onPressed: onSuspend,
                  icon: const Icon(Icons.block,
                      color: Colors.red),
                  tooltip: 'Suspender',
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getName() =>
      (user['nombre'] ?? user['name'] ?? '').toString();
  String _getEmail() => (user['email'] ?? '').toString();
  String _getRole() =>
      (user['rol'] ?? user['role'] ?? 'client').toString();

  Color _avatarColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'provider':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}
