import React from 'react';
import { Routes, Route } from 'react-router-dom';
import MainLayout from '../layouts/MainLayout';
import ProtectedRoute from '../components/ProtectedRoute';
import Login from '../pages/login/Login';
import Signup from '../pages/signup/Signup';
import ForgotPassword from '../pages/forgot-password/ForgotPassword';
import Dashboard      from '../pages/dashboard/Dashboard';
import Verification   from '../pages/verification/Verification';
import Bookings       from '../pages/bookings/Bookings';
import ProviderProfile from '../pages/admin/ProviderProfile/ProviderProfile';
import Complaints      from '../pages/complaints/Complaints';
import Analytics      from '../pages/analytics/Analytics';
import Categories     from '../pages/admin/Categories/Categories';
import Notifications  from '../pages/notifications/Notifications';
import Blocked        from '../pages/blocked/Blocked';
import Settings       from '../pages/settings/Settings';
import AdminProfile   from '../pages/admin/Profile/AdminProfile';
import QuizQuestions  from '../pages/quiz/QuizQuestions';
import UserManagement from '../pages/users/UserManagement';

export default function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/signup" element={<Signup />} />
      <Route path="/forgot-password" element={<ForgotPassword />} />
      
      <Route element={<ProtectedRoute />}>
        <Route path="/" element={<MainLayout />}>
          <Route index            element={<Dashboard />} />
          <Route path="users"     element={<UserManagement />} />
          <Route path="reviews/:id" element={<ProviderProfile />} />
          <Route path="verification" element={<Verification />} />
          <Route path="quiz-questions" element={<QuizQuestions />} />
          <Route path="bookings"  element={<Bookings />} />
          <Route path="categories" element={<Categories />} />
          <Route path="complaints" element={<Complaints />} />
          <Route path="notifications" element={<Notifications />} />
          <Route path="analytics" element={<Analytics />} />
          <Route path="blocked"   element={<Blocked />} />
          <Route path="settings"  element={<Settings />} />
          <Route path="profile"   element={<AdminProfile />} />
        </Route>
      </Route>
    </Routes>
  );
}