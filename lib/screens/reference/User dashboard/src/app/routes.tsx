import { createBrowserRouter } from 'react-router';
import { PhoneLayout } from './layout/PhoneLayout';
import { MainLayout } from './layout/MainLayout';
import { SplashScreen } from './screens/SplashScreen';
import { LoginScreen } from './screens/LoginScreen';
import { RegisterScreen } from './screens/RegisterScreen';
import { HomeScreen } from './screens/HomeScreen';
import { CameraScreen } from './screens/CameraScreen';
import { FeedScreen } from './screens/FeedScreen';
import { LeaderboardScreen } from './screens/LeaderboardScreen';
import { ProfileScreen } from './screens/ProfileScreen';
import { NotificationsScreen } from './screens/NotificationsScreen';
import { SettingsScreen } from './screens/SettingsScreen';
import { AllSubmissionsScreen } from './screens/AllSubmissionsScreen';
import { PostDetailScreen } from './screens/PostDetailScreen';
import { EditProfileScreen } from './screens/EditProfileScreen';

export const router = createBrowserRouter([
  {
    path: '/',
    Component: PhoneLayout,
    children: [
      { index: true, Component: SplashScreen },
      { path: 'login', Component: LoginScreen },
      { path: 'register', Component: RegisterScreen },
      { path: 'camera', Component: CameraScreen },
      { path: 'notifications', Component: NotificationsScreen },
      { path: 'settings', Component: SettingsScreen },
      { path: 'profile/submissions', Component: AllSubmissionsScreen },
      { path: 'profile/edit', Component: EditProfileScreen },
      { path: 'post/:id', Component: PostDetailScreen },
      {
        Component: MainLayout,
        children: [
          { path: 'home', Component: HomeScreen },
          { path: 'feed', Component: FeedScreen },
          { path: 'leaderboard', Component: LeaderboardScreen },
          { path: 'profile', Component: ProfileScreen },
        ],
      },
    ],
  },
]);
