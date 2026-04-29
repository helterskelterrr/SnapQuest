import React, { useState, useRef } from 'react';
import { useNavigate } from 'react-router';
import { ArrowLeft, Mail, Lock, Eye, EyeOff, AlertCircle } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Toast } from '../components/Toast';

function validateEmail(v: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
}

interface FieldProps {
  label: string;
  icon: React.ReactNode;
  type: string;
  placeholder: string;
  value: string;
  onChange: (v: string) => void;
  error?: string;
  onBlur?: () => void;
  rightEl?: React.ReactNode;
  focused: boolean;
  onFocus: () => void;
  onBlurField: () => void;
}

function Field({ label, icon, type, placeholder, value, onChange, error, rightEl, focused, onFocus, onBlurField }: FieldProps) {
  return (
    <div>
      <label style={{ color: error ? '#E07B65' : '#4A706B', fontSize: '13px', fontWeight: 600, display: 'block', marginBottom: '8px', transition: 'color 0.2s' }}>
        {label}
      </label>
      <div className="relative">
        <div className="absolute left-4 top-1/2 -translate-y-1/2" style={{ pointerEvents: 'none', transition: 'opacity 0.2s' }}>
          {icon}
        </div>
        <input
          type={type}
          placeholder={placeholder}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onFocus={onFocus}
          onBlur={onBlurField}
          style={{
            width: '100%', height: '56px', borderRadius: '14px',
            background: error ? 'rgba(224,123,101,0.04)' : focused ? 'white' : '#FAFAF8',
            border: `1.5px solid ${error ? '#E07B65' : focused ? '#97B3AE' : '#D6CBBF'}`,
            color: '#2C3A37', fontSize: '15px',
            paddingLeft: '44px', paddingRight: rightEl ? '48px' : '16px',
            outline: 'none', boxSizing: 'border-box',
            fontFamily: "'Plus Jakarta Sans', sans-serif",
            transition: 'border-color 0.2s, background 0.2s',
            boxShadow: focused ? '0 0 0 3px rgba(151,179,174,0.15)' : 'none',
          } as React.CSSProperties}
        />
        {rightEl && (
          <div className="absolute right-4 top-1/2 -translate-y-1/2">{rightEl}</div>
        )}
      </div>
      <AnimatePresence>
        {error && (
          <motion.div
            initial={{ opacity: 0, y: -4, height: 0 }}
            animate={{ opacity: 1, y: 0, height: 'auto' }}
            exit={{ opacity: 0, y: -4, height: 0 }}
            className="flex items-center gap-1.5 mt-2"
          >
            <AlertCircle size={12} color="#E07B65" />
            <span style={{ color: '#E07B65', fontSize: '12px' }}>{error}</span>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

export function LoginScreen() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [touched, setTouched] = useState({ email: false, password: false });
  const [focused, setFocused] = useState({ email: false, password: false });
  const [shake, setShake] = useState(false);
  const [toast, setToast] = useState<{ msg: string; type: 'error' | 'success' | 'info' | 'warning' } | null>(null);

  const emailErr = touched.email && !email ? 'Email tidak boleh kosong'
    : touched.email && email && !validateEmail(email) ? 'Format email tidak valid' : '';
  const passErr = touched.password && !password ? 'Password tidak boleh kosong'
    : touched.password && password && password.length < 6 ? 'Password minimal 6 karakter' : '';

  const showT = (msg: string, type: 'error' | 'success' | 'info' | 'warning' = 'info') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 3000);
  };

  const handleLogin = () => {
    setTouched({ email: true, password: true });
    if (!email || !validateEmail(email) || !password || password.length < 6) {
      setShake(true);
      setTimeout(() => setShake(false), 500);
      return;
    }
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      // Simulate wrong password for demo
      if (password === 'wrong') {
        showT('Email atau password salah. Coba lagi.', 'error');
        setShake(true);
        setTimeout(() => setShake(false), 500);
      } else {
        navigate('/home');
      }
    }, 1400);
  };

  return (
    <div className="flex flex-col overflow-y-auto relative" style={{ height: '800px', background: '#F0EEEA', scrollbarWidth: 'none' } as React.CSSProperties}>
      <div style={{ height: '4px', background: 'linear-gradient(90deg, #97B3AE, #F2C3B9, #D2E0D3)', flexShrink: 0 }} />

      <AnimatePresence>{toast && <Toast message={toast.msg} type={toast.type} onDismiss={() => setToast(null)} />}</AnimatePresence>

      {/* Header */}
      <div className="flex items-center px-6 pt-5 pb-4">
        <button
          onClick={() => navigate('/')}
          style={{ width: '44px', height: '44px', borderRadius: '12px', background: 'white', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', boxShadow: '0 2px 8px rgba(44,58,55,0.06)' }}
        >
          <ArrowLeft size={20} color="#627370" />
        </button>
      </div>

      <motion.div
        animate={shake ? { x: [-8, 8, -6, 6, -4, 0] } : { x: 0 }}
        transition={{ duration: 0.4 }}
        className="flex flex-col flex-1 px-6"
      >
        {/* Hero */}
        <div className="mb-8">
          <div style={{ width: '52px', height: '52px', borderRadius: '16px', background: 'linear-gradient(135deg, #D2E0D3, #97B3AE)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '16px', boxShadow: '0 6px 20px rgba(151,179,174,0.35)' }}>
            <Lock size={22} color="white" strokeWidth={1.6} />
          </div>
          <h1 style={{ color: '#2C3A37', fontSize: '28px', fontWeight: 800, lineHeight: 1.2, marginBottom: '8px' }}>
            Selamat Datang<br />Kembali
          </h1>
          <p style={{ color: '#9EAEAD', fontSize: '14px', lineHeight: 1.6 }}>
            Masuk dan lanjutkan tantangan foto harianmu
          </p>
        </div>

        {/* Fields */}
        <div className="flex flex-col gap-4 mb-2">
          <Field
            label="Email"
            icon={<Mail size={18} color={focused.email ? '#97B3AE' : '#C4D0CE'} />}
            type="email"
            placeholder="nama@email.com"
            value={email}
            onChange={setEmail}
            error={emailErr}
            focused={focused.email}
            onFocus={() => setFocused(p => ({ ...p, email: true }))}
            onBlurField={() => { setFocused(p => ({ ...p, email: false })); setTouched(p => ({ ...p, email: true })); }}
          />
          <Field
            label="Password"
            icon={<Lock size={18} color={focused.password ? '#97B3AE' : '#C4D0CE'} />}
            type={showPassword ? 'text' : 'password'}
            placeholder="Minimal 6 karakter"
            value={password}
            onChange={setPassword}
            error={passErr}
            focused={focused.password}
            onFocus={() => setFocused(p => ({ ...p, password: true }))}
            onBlurField={() => { setFocused(p => ({ ...p, password: false })); setTouched(p => ({ ...p, password: true })); }}
            rightEl={
              <button onClick={() => setShowPassword(!showPassword)} style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: '4px', display: 'flex' }}>
                {showPassword ? <EyeOff size={18} color="#C4D0CE" /> : <Eye size={18} color="#C4D0CE" />}
              </button>
            }
          />
        </div>

        {/* Forgot */}
        <button
          onClick={() => showT('Link reset password telah dikirim ke emailmu', 'info')}
          style={{ textAlign: 'right', background: 'transparent', border: 'none', color: '#97B3AE', fontSize: '13px', fontWeight: 600, cursor: 'pointer', marginBottom: '28px', padding: '4px 0' }}
        >
          Lupa password?
        </button>

        {/* Submit */}
        <motion.button
          whileTap={{ scale: 0.97 }}
          onClick={handleLogin}
          disabled={loading}
          className="w-full flex items-center justify-center gap-2"
          style={{ height: '56px', borderRadius: '14px', background: loading ? 'rgba(151,179,174,0.6)' : '#97B3AE', color: 'white', fontSize: '16px', fontWeight: 700, border: 'none', cursor: loading ? 'not-allowed' : 'pointer', boxShadow: loading ? 'none' : '0 8px 28px rgba(151,179,174,0.4)', marginBottom: '20px', transition: 'background 0.2s' }}
        >
          {loading ? (
            <div style={{ width: '22px', height: '22px', border: '2px solid rgba(255,255,255,0.4)', borderTop: '2px solid white', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
          ) : 'Masuk'}
        </motion.button>

        <p className="text-center" style={{ color: '#9EAEAD', fontSize: '14px' }}>
          Belum punya akun?{' '}
          <button onClick={() => navigate('/register')} style={{ background: 'transparent', border: 'none', color: '#4A706B', fontWeight: 700, cursor: 'pointer', fontSize: '14px' }}>
            Daftar sekarang
          </button>
        </p>
      </motion.div>

      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  );
}
