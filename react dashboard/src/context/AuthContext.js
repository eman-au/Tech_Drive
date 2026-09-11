import React, { createContext, useState, useEffect, useContext } from 'react';
import { 
  onAuthStateChanged, 
  signInWithEmailAndPassword, 
  signOut, 
  sendPasswordResetEmail 
} from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '../config/firebase';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [currentUser, setCurrentUser] = useState(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        try {
          const adminDoc = await getDoc(doc(db, 'admins', user.uid));
          if (adminDoc.exists()) {
            setCurrentUser(user);
            setIsAuthenticated(true);
            setIsAdmin(true);
          } else {
            // Not an admin in admins/{uid} collection
            await signOut(auth);
            setCurrentUser(null);
            setIsAuthenticated(false);
            setIsAdmin(false);
          }
        } catch (error) {
          console.error("Admin verification error:", error);
          await signOut(auth);
          setCurrentUser(null);
          setIsAuthenticated(false);
          setIsAdmin(false);
        }
      } else {
        setCurrentUser(null);
        setIsAuthenticated(false);
        setIsAdmin(false);
      }
      setIsLoading(false);
    });

    return unsubscribe;
  }, []);

  const login = async (email, password) => {
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // Verify admin role in Firestore admins/{uid}
      const adminDoc = await getDoc(doc(db, 'admins', user.uid));
      if (!adminDoc.exists()) {
        await signOut(auth);
        return { 
          success: false, 
          error: "Access denied. Your account is not registered in the admin roster." 
        };
      }

      return { success: true, user };
    } catch (error) {
      return { success: false, error: error.message };
    }
  };

  const signup = async () => {
    // Disabled public admin creation for security
    return { 
      success: false, 
      error: "Public admin registration is disabled for security reasons." 
    };
  };

  const logout = async () => {
    try {
      await signOut(auth);
      localStorage.removeItem('techDrive_isAuthenticated');
    } catch (error) {
      console.error("Logout error", error);
    }
  };

  const resetPassword = async (email) => {
    try {
      await sendPasswordResetEmail(auth, email);
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  };

  return (
    <AuthContext.Provider value={{ 
      currentUser, 
      isAuthenticated, 
      isAdmin,
      login, 
      signup, 
      logout, 
      resetPassword,
      isLoading 
    }}>
      {!isLoading && children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
