import React, { useState } from 'react';
import { useNavigate } from 'react-router';
import { ArrowLeft, User, Mail, Lock, Eye, EyeOff, Camera, Check, AlertCircle } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Toast } from '../components/Toast';

const AVATAR_OPTIONS = [
  { color: '#97B3AE' }, { color: '#F2C3B9' }, { color: '#D2E0D3' },
  { color: '#D6CBBF' }, { color: '#B8C9C7' }, { color: '#E8A89E' },
];

function validateEmail(v: string) { return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v); }

function StrengthBar({ password }: { password: string }) {
  const score = [password.length >= 8, /[A-Z]/.test(password), /[0-9]/.test(password), /[^A-Za-z0-9]/.test(password)].filter(Boolean).length;
  const labels = ['', 'Lemah', 'Cukup', 'Kuat', 'Sangat Kuat'];
  const colors = ['#E8E0D8', '#E07B65', '#E07B65', '#97B3AE', '#4A706B'];
  if (!password) return null;
  return (
    <div className="mt-2">
      <div className="flex gap-1 mb-1">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} style={{ flex: 1, height: '3px', borderRadius: '2px', background: i <= score ? colors[score] : '#E8E0D8', transition: 'background 0.3s' }} />
        ))}
      </div>
      <p style={{ color: colors[score], fontSize: '11px', fontWeight: 600 }}>{labels[score]}</p>
    </div>
  );
}

function FieldErr({ error }: { error?: string }) {
  return (
    <AnimatePresence>
      {error && (
        <motion.div initial={{ opacity: 0, y: -4, height: 0 }} animate={{ opacity: 1, y: 0, height: 'auto' }} exit={{ opacity: 0, y: -4, height: 0 }} className="flex items-center gap-1.5 mt-2">
          <AlertCircle size={12} color="#E07B65" />
          <span style={{ color: '#E07B65', fontSize: '12px' }}>{error}</span>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

function InputField({ label, icon, type, placeholder, value, onChange, error, focused, onFocus, onBlur, rightEl }: {
  label: string; icon: React.ReactNode; type: string; placeholder: string;
  value: string; onChange: (v: string) => void; error?: string;
  focused: boolean; onFocus: () => void; onBlur: () => void; rightEl?: React.ReactNode;
}) {
  return (
    <div>
      <label style={{ color: error ? '#E07B65' : '#4A706B', fontSize: '13px', fontWeight: 600, display: 'block', marginBottom: '8px' }}>{label}</label>
      <div className="relative">
        <div className="absolute left-4 top-1/2 -translate-y-1/2" style={{ pointerEvents: 'none' }}>{icon}</div>
        <input
          type={type} placeholder={placeholder} value={value}
          onChange={(e) => onChange(e.target.value)} onFocus={onFocus} onBlur={onBlur}
          style={{ width: '100%', height: '56px', borderRadius: '14px', background: focused ? 'white' : '#FAFAF8', border: `1.5px solid ${error ? '#E07B65' : focused ? '#97B3AE' : '#D6CBBF'}`, color: '#2C3A37', fontSize: '15px', paddingLeft: '44px', paddingRight: rightEl ? '48px' : '16px', outline: 'none', boxSizing: 'border-box', fontFamily: "'Plus Jakarta Sans', sans-serif", transition: 'border-color 0.2s, background 0.2s', boxShadow: focused ? '0 0 0 3px rgba(151,179,174,0.15)' : 'none' } as React.CSSProperties}
        />
        {rightEl && <div className="absolute right-4 top-1/2 -translate-y-1/2">{rightEl}</div>}
      </div>
      <FieldErr error={error} />
    </div>
  );
}

export function RegisterScreen() {
  const navigate = useNavigate();
  const [displayName, setDisplayName] = useState('');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [showPw, setShowPw] = useState(false);
  const [showConf, setShowConf] = useState(false);
  const [loading, setLoading] = useState(false);
  const [selectedColor, setSelectedColor] = useState(0);
  const [touched, setTouched] = useState({ name: false, username: false, email: false, password: false, confirm: false });
  const [focused, setFocused] = useState({ name: false, username: false, email: false, password: false, confirm: false });
  const [toast, setToast] = useState<{ msg: string; type: 'error' | 'success' | 'info' | 'warning' } | null>(null);

  const showT = (msg: string, type: 'error' | 'success' | 'info' | 'warning' = 'info') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 3000);
  };

  const nameErr = touched.name && !displayName ? 'Nama tidak boleh kosong' : touched.name && displayName.length < 2 ? 'Nama minimal 2 karakter' : '';
  const userErr = touched.username && !username ? 'Username tidak boleh kosong' : touched.username && username.length < 3 ? 'Username minimal 3 karakter' : '';
  const emailErr = touched.email && !email ? 'Email tidak boleh kosong' : touched.email && email && !validateEmail(email) ? 'Format email tidak valid' : '';
  const passErr = touched.password && !password ? 'Password tidak boleh kosong' : touched.password && password.length < 6 ? 'Password minimal 6 karakter' : '';
  const confErr = touched.confirm && confirm !== password ? 'Password tidak cocok' : '';

  const handleRegister = () => {
    setTouched({ name: true, username: true, email: true, password: true, confirm: true });
    if (!displayName || displayName.length < 2 || !username || username.length < 3 || !email || !validateEmail(email) || !password || password.length < 6 || confirm !== password) {
      showT('Harap periksa kembali semua isian', 'error');
      return;
    }
    setLoading(true);
    setTimeout(() => { setLoading(false); navigate('/home'); }, 1400);
  };

  const avatarInitial = displayName ? displayName.slice(0, 2).toUpperCase() : '?';
  const avatarColor = AVATAR_OPTIONS[selectedColor].color;

  return (
    <div className="flex flex-col overflow-y-auto relative" style={{ height: '800px', background: '#F0EEEA', scrollbarWidth: 'none' } as React.CSSProperties}>
      <div style={{ height: '4px', background: 'linear-gradient(90deg, #97B3AE, #F2C3B9, #D2E0D3)', flexShrink: 0 }} />
      <AnimatePresence>{toast && <Toast message={toast.msg} type={toast.type} onDismiss={() => setToast(null)} />}</AnimatePresence>

      <div className="flex items-center px-6 pt-5 pb-2">
        <button onClick={() => navigate('/login')} style={{ width: '44px', height: '44px', borderRadius: '12px', background: 'white', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', boxShadow: '0 2px 8px rgba(44,58,55,0.06)' }}>
          <ArrowLeft size={20} color="#627370" />
        </button>
        <div className="ml-3">
          <h1 style={{ color: '#2C3A37', fontSize: '22px', fontWeight: 800 }}>Buat Akun Baru</h1>
          <p style={{ color: '#9EAEAD', fontSize: '12px' }}>Bergabung dan mulai tantangan harianmu</p>
        </div>
      </div>

      <div className="flex flex-col flex-1 px-6 pb-8 gap-4">
        {/* Avatar picker */}
        <div className="flex flex-col items-center py-4 gap-3">
          <div className="relative">
            <motion.div
              style={{ width: '80px', height: '80px', borderRadius: '50%', background: avatarColor, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '24px', fontWeight: 800, color: 'white', border: '3px solid white', boxShadow: `0 8px 28px ${avatarColor}60`, transition: 'background 0.3s, box-shadow 0.3s' }}
            >
              {avatarInitial}
            </motion.div>
            <div style={{ position: 'absolute', bottom: 0, right: 0, width: '26px', height: '26px', borderRadius: '50%', background: '#97B3AE', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '2px solid #F0EEEA' }}>
              <Camera size={12} color="white" />
            </div>
          </div>
          <div className="flex gap-2">
            {AVATAR_OPTIONS.map((opt, i) => (
              <motion.button key={i} whileTap={{ scale: 0.85 }} onClick={() => setSelectedColor(i)}
                style={{ width: '34px', height: '34px', borderRadius: '50%', background: opt.color, border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: selectedColor === i ? `0 0 0 2.5px white, 0 0 0 4.5px ${opt.color}, 0 4px 12px ${opt.color}70` : '0 2px 6px rgba(0,0,0,0.08)', transition: 'all 0.15s' }}>
                {selectedColor === i && <Check size={14} color="white" strokeWidth={3} />}
              </motion.button>
            ))}
          </div>
        </div>

        <InputField label="Nama Tampilan" icon={<User size={18} color={focused.name ? '#97B3AE' : '#C4D0CE'} />} type="text" placeholder="Nama lengkap kamu" value={displayName} onChange={setDisplayName} error={nameErr} focused={focused.name} onFocus={() => setFocused(p => ({ ...p, name: true }))} onBlur={() => { setFocused(p => ({ ...p, name: false })); setTouched(p => ({ ...p, name: true })); }} />

        <div>
          <label style={{ color: userErr ? '#E07B65' : '#4A706B', fontSize: '13px', fontWeight: 600, display: 'block', marginBottom: '8px' }}>Username</label>
          <div className="relative">
            <div className="absolute left-4 top-1/2 -translate-y-1/2" style={{ color: '#C4D0CE', fontSize: '15px', fontWeight: 500, pointerEvents: 'none' }}>@</div>
            <input
              type="text" placeholder="username_kamu"
              value={username} onChange={(e) => setUsername(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
              onFocus={() => setFocused(p => ({ ...p, username: true }))}
              onBlur={() => { setFocused(p => ({ ...p, username: false })); setTouched(p => ({ ...p, username: true })); }}
              style={{ width: '100%', height: '56px', borderRadius: '14px', background: focused.username ? 'white' : '#FAFAF8', border: `1.5px solid ${userErr ? '#E07B65' : focused.username ? '#97B3AE' : '#D6CBBF'}`, color: '#2C3A37', fontSize: '15px', paddingLeft: '30px', paddingRight: '16px', outline: 'none', boxSizing: 'border-box', fontFamily: "'Plus Jakarta Sans', sans-serif", boxShadow: focused.username ? '0 0 0 3px rgba(151,179,174,0.15)' : 'none', transition: 'all 0.2s' } as React.CSSProperties}
            />
          </div>
          <FieldErr error={userErr} />
          {!userErr && <p style={{ color: '#C4D0CE', fontSize: '11px', marginTop: '4px' }}>Huruf kecil, angka, dan underscore saja</p>}
        </div>

        <InputField label="Email" icon={<Mail size={18} color={focused.email ? '#97B3AE' : '#C4D0CE'} />} type="email" placeholder="nama@email.com" value={email} onChange={setEmail} error={emailErr} focused={focused.email} onFocus={() => setFocused(p => ({ ...p, email: true }))} onBlur={() => { setFocused(p => ({ ...p, email: false })); setTouched(p => ({ ...p, email: true })); }} />

        <div>
          <InputField label="Password" icon={<Lock size={18} color={focused.password ? '#97B3AE' : '#C4D0CE'} />} type={showPw ? 'text' : 'password'} placeholder="Minimal 6 karakter" value={password} onChange={setPassword} error={passErr} focused={focused.password} onFocus={() => setFocused(p => ({ ...p, password: true }))} onBlur={() => { setFocused(p => ({ ...p, password: false })); setTouched(p => ({ ...p, password: true })); }}
            rightEl={<button onClick={() => setShowPw(!showPw)} style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: '4px', display: 'flex' }}>{showPw ? <EyeOff size={18} color="#C4D0CE" /> : <Eye size={18} color="#C4D0CE" />}</button>}
          />
          <StrengthBar password={password} />
        </div>

        <InputField label="Konfirmasi Password" icon={<Lock size={18} color={focused.confirm ? '#97B3AE' : '#C4D0CE'} />} type={showConf ? 'text' : 'password'} placeholder="Ulangi password" value={confirm} onChange={setConfirm} error={confErr} focused={focused.confirm} onFocus={() => setFocused(p => ({ ...p, confirm: true }))} onBlur={() => { setFocused(p => ({ ...p, confirm: false })); setTouched(p => ({ ...p, confirm: true })); }}
          rightEl={<button onClick={() => setShowConf(!showConf)} style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: '4px', display: 'flex' }}>{showConf ? <EyeOff size={18} color="#C4D0CE" /> : <Eye size={18} color="#C4D0CE" />}</button>}
        />

        <p style={{ color: '#C4D0CE', fontSize: '12px', lineHeight: 1.6 }}>
          Dengan mendaftar, kamu setuju dengan <span style={{ color: '#4A706B', cursor: 'pointer' }}>Syarat &amp; Ketentuan</span> dan <span style={{ color: '#4A706B', cursor: 'pointer' }}>Kebijakan Privasi</span>.
        </p>

        <motion.button whileTap={{ scale: 0.97 }} onClick={handleRegister} disabled={loading} className="w-full flex items-center justify-center gap-2"
          style={{ height: '56px', borderRadius: '14px', background: loading ? 'rgba(151,179,174,0.6)' : '#97B3AE', color: 'white', fontSize: '16px', fontWeight: 700, border: 'none', cursor: loading ? 'not-allowed' : 'pointer', boxShadow: loading ? 'none' : '0 8px 28px rgba(151,179,174,0.4)', transition: 'background 0.2s' }}>
          {loading ? <div style={{ width: '22px', height: '22px', border: '2px solid rgba(255,255,255,0.4)', borderTop: '2px solid white', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} /> : 'Buat Akun'}
        </motion.button>

        <p className="text-center" style={{ color: '#9EAEAD', fontSize: '14px' }}>
          Sudah punya akun?{' '}
          <button onClick={() => navigate('/login')} style={{ background: 'transparent', border: 'none', color: '#4A706B', fontWeight: 700, cursor: 'pointer', fontSize: '14px' }}>Masuk</button>
        </p>
      </div>
      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  );
}
