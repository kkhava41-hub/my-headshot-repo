#!/usr/bin/env python3
"""
AX Manager Plugin - Advanced System Management
Professional plugin for Headshot Management System
Version: 1.0.0
"""

import os
import json
import sqlite3
from datetime import datetime
from pathlib import Path


class AXCore:
    """AX Manager Core Engine"""
    
    def __init__(self, app_name="Headshot Management"):
        """Initialize AX Core"""
        self.app_name = app_name
        self.version = "1.0.0"
        self.initialized = False
        self.plugins = {}
        self.config = {}
        self.logger = None
        
        print(f"✓ AX Core initialized: {app_name} v{self.version}")
    
    def register_plugin(self, plugin_name, plugin_instance):
        """Register a plugin"""
        self.plugins[plugin_name] = plugin_instance
        return True
    
    def get_plugin(self, plugin_name):
        """Get a registered plugin"""
        return self.plugins.get(plugin_name)
    
    def list_plugins(self):
        """List all registered plugins"""
        return list(self.plugins.keys())


class AXDataManager:
    """AX Data Management Plugin"""
    
    def __init__(self, db_name="ax_manager.db"):
        """Initialize data manager"""
        self.db_name = db_name
        self.connection = None
        self.cursor = None
        self.init_connection()
    
    def init_connection(self):
        """Initialize database connection"""
        try:
            self.connection = sqlite3.connect(self.db_name)
            self.cursor = self.connection.cursor()
            self.create_tables()
            print(f"✓ Data Manager initialized: {self.db_name}")
        except Exception as e:
            print(f"✗ Error initializing data manager: {e}")
    
    def create_tables(self):
        """Create required tables"""
        
        # Headshots table
        self.cursor.execute("""
            CREATE TABLE IF NOT EXISTS headshots (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                image_path TEXT,
                title TEXT,
                bio TEXT,
                email TEXT UNIQUE,
                phone TEXT,
                department TEXT,
                status TEXT DEFAULT 'active',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Projects table
        self.cursor.execute("""
            CREATE TABLE IF NOT EXISTS projects (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Assignments table
        self.cursor.execute("""
            CREATE TABLE IF NOT EXISTS assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                headshot_id INTEGER NOT NULL,
                project_id INTEGER NOT NULL,
                role TEXT,
                FOREIGN KEY(headshot_id) REFERENCES headshots(id),
                FOREIGN KEY(project_id) REFERENCES projects(id)
            )
        """)
        
        # Audit log
        self.cursor.execute("""
            CREATE TABLE IF NOT EXISTS audit_log (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                action TEXT NOT NULL,
                entity_type TEXT,
                entity_id INTEGER,
                details TEXT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        self.connection.commit()
    
    def add_headshot(self, name, image_path, title, bio, email, phone, department=""):
        """Add headshot with department"""
        try:
            self.cursor.execute("""
                INSERT INTO headshots (name, image_path, title, bio, email, phone, department)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (name, image_path, title, bio, email, phone, department))
            self.connection.commit()
            self.log_action("CREATE", "headshot", self.cursor.lastrowid, f"Added {name}")
            return self.cursor.lastrowid
        except sqlite3.IntegrityError:
            print(f"✗ Error: Email {email} already exists")
            return None
    
    def get_all_headshots(self, department=None):
        """Get headshots, optionally filtered by department"""
        if department:
            self.cursor.execute("SELECT * FROM headshots WHERE department = ?", (department,))
        else:
            self.cursor.execute("SELECT * FROM headshots")
        return self.cursor.fetchall()
    
    def search_headshot(self, keyword):
        """Search headshots"""
        self.cursor.execute("""
            SELECT * FROM headshots WHERE name LIKE ? OR email LIKE ? OR department LIKE ?
        """, (f"%{keyword}%", f"%{keyword}%", f"%{keyword}%"))
        return self.cursor.fetchall()
    
    def update_headshot(self, headshot_id, **kwargs):
        """Update headshot"""
        allowed_fields = ['name', 'image_path', 'title', 'bio', 'email', 'phone', 'department', 'status']
        updates = {k: v for k, v in kwargs.items() if k in allowed_fields}
        
        if not updates:
            return False
        
        updates['updated_at'] = datetime.now().isoformat()
        set_clause = ", ".join([f"{k} = ?" for k in updates.keys()])
        values = list(updates.values()) + [headshot_id]
        
        try:
            self.cursor.execute(f"UPDATE headshots SET {set_clause} WHERE id = ?", values)
            self.connection.commit()
            self.log_action("UPDATE", "headshot", headshot_id, json.dumps(updates))
            return True
        except Exception as e:
            print(f"✗ Error updating headshot: {e}")
            return False
    
    def delete_headshot(self, headshot_id):
        """Delete headshot"""
        try:
            self.cursor.execute("DELETE FROM headshots WHERE id = ?", (headshot_id,))
            self.connection.commit()
            self.log_action("DELETE", "headshot", headshot_id, "Deleted")
            return True
        except Exception as e:
            print(f"✗ Error deleting headshot: {e}")
            return False
    
    def add_project(self, name, description=""):
        """Add project"""
        self.cursor.execute("""
            INSERT INTO projects (name, description)
            VALUES (?, ?)
        """, (name, description))
        self.connection.commit()
        self.log_action("CREATE", "project", self.cursor.lastrowid, f"Added {name}")
        return self.cursor.lastrowid
    
    def assign_to_project(self, headshot_id, project_id, role="Member"):
        """Assign headshot to project"""
        self.cursor.execute("""
            INSERT INTO assignments (headshot_id, project_id, role)
            VALUES (?, ?, ?)
        """, (headshot_id, project_id, role))
        self.connection.commit()
        self.log_action("ASSIGN", "project", project_id, f"Assigned headshot {headshot_id}")
        return True
    
    def log_action(self, action, entity_type, entity_id, details=""):
        """Log action for audit"""
        self.cursor.execute("""
            INSERT INTO audit_log (action, entity_type, entity_id, details)
            VALUES (?, ?, ?, ?)
        """, (action, entity_type, entity_id, details))
        self.connection.commit()
    
    def get_audit_log(self, limit=50):
        """Get audit log"""
        self.cursor.execute("""
            SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT ?
        """, (limit,))
        return self.cursor.fetchall()
    
    def close(self):
        """Close database connection"""
        if self.connection:
            self.connection.close()


class AXReportGenerator:
    """AX Report Generation Plugin"""
    
    def __init__(self, data_manager):
        """Initialize report generator"""
        self.data_manager = data_manager
        print("✓ Report Generator initialized")
    
    def generate_summary_report(self):
        """Generate summary report"""
        headshots = self.data_manager.get_all_headshots()
        
        report = {
            "title": "Headshot System Summary Report",
            "generated_at": datetime.now().isoformat(),
            "total_headshots": len(headshots),
            "departments": {},
            "statuses": {}
        }
        
        for hs in headshots:
            dept = hs[7] or "Unassigned"
            status = hs[8] or "unknown"
            
            report["departments"][dept] = report["departments"].get(dept, 0) + 1
            report["statuses"][status] = report["statuses"].get(status, 0) + 1
        
        return report
    
    def generate_department_report(self, department):
        """Generate department report"""
        headshots = self.data_manager.get_all_headshots(department=department)
        
        report = {
            "title": f"Department Report: {department}",
            "generated_at": datetime.now().isoformat(),
            "department": department,
            "total_members": len(headshots),
            "members": [
                {
                    "name": hs[1],
                    "title": hs[3],
                    "email": hs[5],
                    "phone": hs[6]
                }
                for hs in headshots
            ]
        }
        
        return report
    
    def export_report_json(self, report, filename):
        """Export report to JSON"""
        try:
            with open(filename, 'w') as f:
                json.dump(report, f, indent=2)
            print(f"✓ Report exported: {filename}")
            return True
        except Exception as e:
            print(f"✗ Error exporting report: {e}")
            return False
    
    def print_report(self, report):
        """Print report to console"""
        print("\n" + "="*70)
        print(f"📊 {report.get('title', 'Report')}")
        print("="*70)
        print(f"Generated: {report.get('generated_at', 'N/A')}")
        print()
        
        for key, value in report.items():
            if key not in ['title', 'generated_at', 'members']:
                if isinstance(value, dict):
                    print(f"{key}:")
                    for k, v in value.items():
                        print(f"  - {k}: {v}")
                else:
                    print(f"{key}: {value}")
        
        if 'members' in report:
            print("\nMembers:")
            for member in report['members']:
                print(f"  - {member['name']} ({member['title']})")
        
        print("="*70 + "\n")


class AXSecurityManager:
    """AX Security Management Plugin"""
    
    def __init__(self):
        """Initialize security manager"""
        self.users = {}
        self.permissions = {}
        print("✓ Security Manager initialized")
    
    def create_user(self, username, password, role="user"):
        """Create user (simplified - no real hashing)"""
        self.users[username] = {
            "password": password,  # In production, use proper hashing!
            "role": role,
            "created_at": datetime.now().isoformat()
        }
        return True
    
    def authenticate(self, username, password):
        """Authenticate user"""
        user = self.users.get(username)
        if user and user["password"] == password:
            return True
        return False
    
    def set_permission(self, role, permission, allowed=True):
        """Set permission for role"""
        if role not in self.permissions:
            self.permissions[role] = {}
        self.permissions[role][permission] = allowed
    
    def check_permission(self, role, permission):
        """Check if role has permission"""
        return self.permissions.get(role, {}).get(permission, False)


class AXNotificationManager:
    """AX Notification Management Plugin"""
    
    def __init__(self):
        """Initialize notification manager"""
        self.notifications = []
        print("✓ Notification Manager initialized")
    
    def send_notification(self, title, message, notification_type="info"):
        """Send notification"""
        notification = {
            "id": len(self.notifications) + 1,
            "title": title,
            "message": message,
            "type": notification_type,
            "timestamp": datetime.now().isoformat(),
            "read": False
        }
        self.notifications.append(notification)
        return notification["id"]
    
    def get_unread_notifications(self):
        """Get unread notifications"""
        return [n for n in self.notifications if not n["read"]]
    
    def mark_as_read(self, notification_id):
        """Mark notification as read"""
        for n in self.notifications:
            if n["id"] == notification_id:
                n["read"] = True
                return True
        return False
    
    def get_all_notifications(self):
        """Get all notifications"""
        return self.notifications


class AXManager:
    """Main AX Manager Class - Complete System Manager"""
    
    def __init__(self, app_name="Headshot Management System"):
        """Initialize AX Manager"""
        self.core = AXCore(app_name)
        self.data_manager = AXDataManager()
        self.report_generator = AXReportGenerator(self.data_manager)
        self.security_manager = AXSecurityManager()
        self.notification_manager = AXNotificationManager()
        
        # Register plugins
        self.core.register_plugin("data_manager", self.data_manager)
        self.core.register_plugin("report_generator", self.report_generator)
        self.core.register_plugin("security_manager", self.security_manager)
        self.core.register_plugin("notification_manager", self.notification_manager)
        
        print("\n" + "="*70)
        print("✓ AX Manager fully initialized!")
        print("="*70 + "\n")
    
    def display_status(self):
        """Display system status"""
        print("\n" + "="*70)
        print("📊 AX MANAGER SYSTEM STATUS")
        print("="*70)
        print(f"Application: {self.core.app_name}")
        print(f"Version: {self.core.version}")
        print(f"Registered Plugins: {len(self.core.list_plugins())}")
        print(f"Plugins: {', '.join(self.core.list_plugins())}")
        print("="*70 + "\n")
    
    def shutdown(self):
        """Shutdown AX Manager"""
        self.data_manager.close()
        print("✓ AX Manager shutdown complete")


# Demo/Testing
if __name__ == "__main__":
    print("\n" + "╔" + "="*68 + "╗")
    print("║" + " "*15 + "🔧 AX MANAGER PLUGIN - SYSTEM DEMO 🔧" + " "*14 + "║")
    print("╚" + "="*68 + "╝\n")
    
    # Initialize AX Manager
    ax_manager = AXManager()
    ax_manager.display_status()
    
    # Add sample headshots
    print("Adding sample headshots...\n")
    
    ax_manager.data_manager.add_headshot(
        name="John Doe",
        image_path="/images/john.jpg",
        title="Senior Engineer",
        bio="Full-stack developer",
        email="john@company.com",
        phone="+1-555-0101",
        department="Engineering"
    )
    
    ax_manager.data_manager.add_headshot(
        name="Jane Smith",
        image_path="/images/jane.jpg",
        title="Product Manager",
        bio="Product strategy expert",
        email="jane@company.com",
        phone="+1-555-0102",
        department="Product"
    )
    
    ax_manager.data_manager.add_headshot(
        name="Mike Johnson",
        image_path="/images/mike.jpg",
        title="UX Designer",
        bio="Design thinking expert",
        email="mike@company.com",
        phone="+1-555-0103",
        department="Design"
    )
    
    print("✓ Sample data added\n")
    
    # Generate summary report
    print("Generating summary report...\n")
    summary_report = ax_manager.report_generator.generate_summary_report()
    ax_manager.report_generator.print_report(summary_report)
    
    # Generate department report
    print("Generating Engineering department report...\n")
    dept_report = ax_manager.report_generator.generate_department_report("Engineering")
    ax_manager.report_generator.print_report(dept_report)
    
    # Create users and set permissions
    print("Setting up security...\n")
    ax_manager.security_manager.create_user("admin", "admin123", "admin")
    ax_manager.security_manager.create_user("user", "user123", "user")
    ax_manager.security_manager.set_permission("admin", "edit_headshots", True)
    ax_manager.security_manager.set_permission("admin", "delete_headshots", True)
    ax_manager.security_manager.set_permission("user", "view_headshots", True)
    
    print("✓ Security setup complete\n")
    
    # Send notifications
    print("Sending notifications...\n")
    ax_manager.notification_manager.send_notification(
        "System Ready",
        "AX Manager is ready for use",
        "success"
    )
    ax_manager.notification_manager.send_notification(
        "Data Added",
        "Sample headshots have been added",
        "info"
    )
    
    print(f"✓ {len(ax_manager.notification_manager.get_unread_notifications())} unread notifications\n")
    
    # Shutdown
    ax_manager.shutdown()
    print("\n" + "="*70)
    print("Demo completed successfully!")
    print("="*70 + "\n")
