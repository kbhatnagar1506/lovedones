"""
Family Contacts Management System
Stores and manages family member phone numbers for emergency calls
"""

import json
import os
from typing import List, Dict, Optional
from datetime import datetime

class FamilyContact:
    def __init__(self, name: str, phone: str, relationship: str, priority: int = 1):
        self.name = name
        self.phone = phone
        self.relationship = relationship
        self.priority = priority  # 1 = highest priority, 3 = lowest
        self.last_called = None
        self.call_count = 0
    
    def to_dict(self):
        return {
            "name": self.name,
            "phone": self.phone,
            "relationship": self.relationship,
            "priority": self.priority,
            "last_called": self.last_called,
            "call_count": self.call_count
        }
    
    @classmethod
    def from_dict(cls, data: dict):
        contact = cls(
            name=data["name"],
            phone=data["phone"],
            relationship=data["relationship"],
            priority=data.get("priority", 1)
        )
        contact.last_called = data.get("last_called")
        contact.call_count = data.get("call_count", 0)
        return contact

class FamilyContactsManager:
    def __init__(self, contacts_file: str = "family_contacts.json"):
        self.contacts_file = contacts_file
        self.contacts: List[FamilyContact] = []
        self.load_contacts()
    
    def load_contacts(self):
        """Load contacts from JSON file"""
        if os.path.exists(self.contacts_file):
            try:
                with open(self.contacts_file, 'r') as f:
                    data = json.load(f)
                    self.contacts = [FamilyContact.from_dict(contact) for contact in data]
            except Exception as e:
                print(f"Error loading contacts: {e}")
                self.contacts = []
        else:
            # Create default contacts for demo
            self.create_default_contacts()
    
    def save_contacts(self):
        """Save contacts to JSON file"""
        try:
            data = [contact.to_dict() for contact in self.contacts]
            with open(self.contacts_file, 'w') as f:
                json.dump(data, f, indent=2)
        except Exception as e:
            print(f"Error saving contacts: {e}")
    
    def create_default_contacts(self):
        """Create default family contacts for demo"""
        default_contacts = [
            FamilyContact("Sarah Johnson", "+14025551234", "Daughter", 1),
            FamilyContact("Michael Johnson", "+14025551235", "Son", 1),
            FamilyContact("Dr. Smith", "+14025551236", "Primary Care Doctor", 2),
            FamilyContact("Emergency Contact", "+14025551237", "Neighbor", 3)
        ]
        self.contacts = default_contacts
        self.save_contacts()
    
    def add_contact(self, name: str, phone: str, relationship: str, priority: int = 1):
        """Add a new family contact"""
        contact = FamilyContact(name, phone, relationship, priority)
        self.contacts.append(contact)
        self.save_contacts()
        return contact
    
    def remove_contact(self, phone: str):
        """Remove a contact by phone number"""
        self.contacts = [c for c in self.contacts if c.phone != phone]
        self.save_contacts()
    
    def get_contacts_by_priority(self) -> List[FamilyContact]:
        """Get contacts sorted by priority (highest first)"""
        return sorted(self.contacts, key=lambda x: x.priority)
    
    def get_emergency_contacts(self) -> List[FamilyContact]:
        """Get high-priority contacts for emergency calls"""
        return [c for c in self.contacts if c.priority <= 2]
    
    def update_call_info(self, phone: str):
        """Update call information for a contact"""
        for contact in self.contacts:
            if contact.phone == phone:
                contact.last_called = datetime.now().isoformat()
                contact.call_count += 1
                break
        self.save_contacts()
    
    def get_contact_by_phone(self, phone: str) -> Optional[FamilyContact]:
        """Get contact by phone number"""
        for contact in self.contacts:
            if contact.phone == phone:
                return contact
        return None
    
    def get_all_contacts(self) -> List[Dict]:
        """Get all contacts as dictionaries"""
        return [contact.to_dict() for contact in self.contacts]

# Global instance
family_contacts = FamilyContactsManager()

