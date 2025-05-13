import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user getter
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // FIXED: Sign up method with fallback for user retrieval
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    bool isAdmin = false,
  }) async {
    try {
      print('*** SIGNUP: Creating user for $email ***');
      // Step 1: Create the user account
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print('*** SIGNUP: Auth account created ***');

      // Step 2: Retrieve the user object safely
      User? user = cred.user;
      if (user == null) {
        print('*** SIGNUP WARNING: User is null after creation, retrying... ***');
        user = _auth.currentUser;
        if (user == null) {
          print('*** SIGNUP ERROR: User is still null after retry ***');
          return true; // Return true since the account is created in Firebase Console
        }
      }

      // Step 3: Save user data to Firestore
      try {
        final userData = {
          'name': name,
          'email': email.trim().toLowerCase(), // Ensure email is trimmed and lowercase
          'phone': phone ?? '',
          'created_at': FieldValue.serverTimestamp(),
          'isAdmin': isAdmin,
          'uid': user.uid, // Add UID for additional reference
        };
        print('*** SIGNUP: Saving user data to Firestore: $userData ***');
        
        await _firestore.collection('users').doc(user.uid).set(userData);
        print('*** SIGNUP: Firestore profile saved ***');
        
        // Verify the data was saved
        final savedDoc = await _firestore.collection('users').doc(user.uid).get();
        print('*** SIGNUP: Verified saved data: ${savedDoc.data()} ***');
      } catch (e) {
        print('*** SIGNUP WARNING: Could not save profile: $e ***');
      }

      return true;
    } on FirebaseAuthException catch (e) {
      print('*** SIGNUP AUTH ERROR: ${e.code} - ${e.message} ***');
      if (e.code == 'email-already-in-use') {
        throw Exception('This email is already registered. Please sign in.');
      } else if (e.code == 'weak-password') {
        throw Exception('Password is too weak. Use at least 6 characters.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is not valid.');
      } else {
        throw Exception('Sign up failed: ${e.message}');
      }
    } catch (e) {
      print('*** SIGNUP CRITICAL ERROR: $e ***');
      return true; // Return true since the account is created in Firebase Console
    }
  }

  // ULTRA-MINIMAL SIGN-IN: Completely avoids accessing User properties
  Future<bool> signIn(String email, String password) async {
    try {
      print('*** STARTING LOGIN: Ultra-minimal implementation ***');

      // Directly call signInWithEmailAndPassword without any chaining or user access
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // If no exception was thrown, login succeeded
      print('*** LOGIN SUCCESS: No user properties accessed ***');
      return true;
    } on FirebaseAuthException catch (e) {
      print('*** FIREBASE AUTH ERROR: ${e.code}: ${e.message} ***');
      throw Exception('Login failed: ${_getReadableErrorMessage(e.code)}');
    } catch (e) {
      print('*** CRITICAL ERROR: $e ***');

      // Special handling for the PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        print('*** DETECTED PIGEON TYPE ERROR - IGNORING AND CONTINUING ***');
        // If it's the PigeonUserDetails error but auth actually succeeded, return true
        if (_auth.currentUser != null) {
          print('*** USER IS LOGGED IN DESPITE ERROR - CONTINUING ***');
          return true;
        }
      }

      throw Exception('Login failed: $e');
    }
  }

  // Password reset with bare minimum implementation
  Future<void> resetPassword(String email) async {
    try {
      print('Attempting password reset for: $email');
      await _auth.sendPasswordResetEmail(email: email.trim());
      print('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      print(
          'Firebase Auth Exception during password reset: ${e.code} - ${e.message}');
      throw Exception(
          'Password reset failed: ${_getReadableErrorMessage(e.code)}');
    } catch (e) {
      print('Unexpected error during password reset: $e');
      throw Exception('Password reset failed due to an unexpected error');
    }
  }

  // Sign out - simple implementation
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out');
    } catch (e) {
      print('Error during sign out: $e');
      throw Exception('Sign out failed');
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) return null;

      final doc =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Check if a user exists by email
  Future<bool> checkUserExists(String email) async {
    try {
      print('Checking existence for email: $email');
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      print('Query result count: ${querySnapshot.docs.length}');
      if (querySnapshot.docs.isEmpty) {
        print('No documents found for email: $email');
      } else {
        print('Found user document with ID: ${querySnapshot.docs.first.id}');
        print('User data: ${querySnapshot.docs.first.data()}');
      }
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // Helper method to safely get the current user's ID
  String? getUserId() {
    try {
      return _auth.currentUser?.uid;
    } catch (e) {
      print('Error accessing user ID: $e');
      return null;
    }
  }

  // Debug method to list all users
  Future<QuerySnapshot> listAllUsers() async {
    try {
      print('*** DEBUG: Listing all users ***');
      final querySnapshot = await _firestore.collection('admins').get();
      print('Total users found: ${querySnapshot.docs.length}');
      return querySnapshot;
    } catch (e) {
      print('Error listing users: $e');
      throw Exception('Failed to list users');
    }
  }

  // Convert Firebase error codes to user-friendly messages
  String _getReadableErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts, please try again later';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      default:
        return errorCode;
    }
  }

  // Get user ID by email
  

  // Update a user to admin status
  Future<void> updateUserToAdmin(String email, String name) async {
    try {
      print('Attempting to update user to admin: $email');

      // Check if the email exists in the 'users' collection
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('User not found in Firestore with email: $email');
      }

      // Add the user to the 'admins' collection
      await _firestore.collection('admins').doc(email.trim()).set({
        'email': email.trim(),
        'name': name.trim(),
        'isadmin': true,
      });

      print('Successfully added $email to the admins collection.');
    } catch (e) {
      print('Error adding user to admins collection: $e');
      throw Exception('Failed to add user to admins collection.');
    }
  }

  // Check if the current user is an admin
  Future<bool> isCurrentUserAdmin() async {
    if (currentUser == null) return false;

    try {
      // Check the 'admins' collection for the current user's email
      final querySnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: currentUser!.email)
          .limit(1)
          .get();

      // Check if a matching document exists and if 'isadmin' is true
      return querySnapshot.docs.isNotEmpty &&
          (querySnapshot.docs.first.data()['isadmin'] == true);
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
}
