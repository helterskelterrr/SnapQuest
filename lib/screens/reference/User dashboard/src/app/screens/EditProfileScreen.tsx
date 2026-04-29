import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router';
import { ArrowLeft, Check, AlertCircle } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Toast } from '../components/Toast';

const COLORS = ['#97B3AE', '#F2C3B9', '#D2E0D3', '#D6CBBF', '#B8C9C7', '#E8A89E', '#A8C8AA', '#C5A98A'];

const INITIAL = { displayName: 'Alex Prasetyo', username: 'alex_pras', bio: 'Fotografer pemula dari Yogyakarta. Suka foto jalanan dan alam.', color: 0 };

export function EditProfileScreen() {
  const navigate = useNavigate();
  const [displayName, setDisplayName] = useState(INITIAL.displayName);
  const [username,    setUsername]    = useState(INITIAL.username);
  const [bio,         setBio]         = useState(INITIAL.bio);
  const [colorIdx,    setColorIdx]    = useState(INITIAL.color);
  const [touched,     setTouched]     = useState({ name: false, username: false });
  const [saving,      setSaving]      = useState(false);
  const [toast, setToast] = useState<{ msg: string; type: 'success' | 'error' | 'info' | 'warning' } | null>(null);

  const showT = (msg: string, type: 'success' | 'error' | 'info' | 'warning' = 'info') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 2500);
  };

  const nameErr = touched.name && !displayName.trim() ? 'Nama tidak boleh kosong'
    : touched.name && displayName.trim().length < 2 ? 'Nama minimal 2 karakter' : '';
  const userErr = touched.username && !username.trim() ? 'Username tidak boleh kosong'
    : touched.username && username.trim().length < 3 ? 'Username minimal 3 karakter' : '';

  const isDirty = displayName !== INITIAL.displayName || username !== INITIAL.username || bio !== INITIAL.bio || colorIdx !== INITIAL.color;

  const handleSave = () => {
    setTouched({ name: true, username: true });
    if (!displayName.trim() || displayName.trim().length < 2 || !username.trim() || username.trim().length < 3) {
      showT('Harap periksa kembali isian', 'error');
      return;
    }
    setSaving(true);
    setTimeout(() => {
      setSaving(false);
      showT('Profil berhasil disimpan!', 'success');
      setTimeout(() => navigate('/profile'), 1000);
    }, 1200);
  };

  const avatarLabel = displayName.trim() ? displayName.trim().slice(0, 2).toUpperCase() : '?';
  const avatarColor = COLORS[colorIdx];

  const inputBase: React.CSSProperties = { width: '100%', borderRadius: '14px', background: '#FAFAF8', color: '#2C3A37', fontSize: '15px', outline: 'none', boxSizing: 'border-box', fontFamily: "'Plus Jakarta Sans', sans-serif", transition: 'all 0.2s' };

  return (
    <div style={{ height: '800px', background: '#F0EEEA', display: 'flex', flexDirection: 'column', overflow: 'hidden', position: 'relative' }}>
      <div style={{ height: '4px', background: 'linear-gradient(90deg, #97B3AE, #F2C3B9, #D2E0D3)', flexShrink: 0 }} />
      <AnimatePresence>{toast && <Toast message={toast.msg} type={toast.type} onDismiss={() => setToast(null)} />}</AnimatePresence>

      {/* Header */}
      <div style={{ padding: '14px 20px', display: 'flex', alignItems: 'center', gap: '12px', flexShrink: 0, background: 'white', borderBottom: '1px solid #F0EEEA' }}>
        <button onClick={() => navigate(-1)}
          style={{ width: '44px', height: '44px', borderRadius: '12px', background: '#FAFAF8', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', flexShrink: 0 }}>
          <ArrowLeft size={20} color="#627370" />
        </button>
        <h2 style={{ color: '#2C3A37', fontSize: '20px', fontWeight: 800, flex: 1 }}>Edit Profil</h2>
        <motion.button whileTap={{ scale: 0.95 }} onClick={handleSave} disabled={saving || !isDirty}
          style={{ padding: '9px 20px', borderRadius: '12px', background: (saving || !isDirty) ? '#F0EEEA' : '#97B3AE', border: 'none', color: (saving || !isDirty) ? '#B8C9C7' : 'white', fontSize: '14px', fontWeight: 700, cursor: (saving || !isDirty) ? 'not-allowed' : 'pointer', display: 'flex', alignItems: 'center', gap: '5px', transition: 'all 0.25s', boxShadow: (saving || !isDirty) ? 'none' : '0 3px 12px rgba(151,179,174,0.35)' }}>
          {saving
            ? <div style={{ width: '16px', height: '16px', border: '2px solid rgba(255,255,255,0.4)', borderTop: '2px solid white', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
            : <><Check size={15} />Simpan</>
          }
        </motion.button>
      </div>

      <div className="flex-1 overflow-y-auto px-5 pb-8" style={{ scrollbarWidth: 'none' } as React.CSSProperties}>
        {/* Avatar */}
        <div className="flex flex-col items-center py-6 gap-3">
          <motion.div
            animate={{ background: avatarColor, boxShadow: `0 8px 28px ${avatarColor}60` }}
            transition={{ duration: 0.3 }}
            style={{ width: '88px', height: '88px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '28px', fontWeight: 800, color: 'white', border: '3px solid white', cursor: 'pointer' }}
          >
            {avatarLabel}
          </motion.div>
          <p style={{ color: '#9EAEAD', fontSize: '12px' }}>Pilih warna avatar</p>
          <div className="flex flex-wrap justify-center gap-2" style={{ maxWidth: '240px' }}>
            {COLORS.map((c, i) => (
              <motion.button key={i} whileTap={{ scale: 0.85 }} onClick={() => setColorIdx(i)}
                style={{ width: '40px', height: '40px', borderRadius: '50%', background: c, border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: colorIdx === i ? `0 0 0 2.5px white, 0 0 0 4.5px ${c}` : '0 2px 6px rgba(0,0,0,0.1)', transition: 'box-shadow 0.15s' }}>
                <AnimatePresence>{colorIdx === i && <motion.div initial={{ scale: 0 }} animate={{ scale: 1 }} exit={{ scale: 0 }}><Check size={16} color="white" strokeWidth={3} /></motion.div>}</AnimatePresence>
              </motion.button>
            ))}
          </div>
        </div>

        {/* Nama */}
        <div className="mb-4">
          <label style={{ color: nameErr ? '#E07B65' : '#4A706B', fontSize: '13px', fontWeight: 600, display: 'block', marginBottom: '8px' }}>Nama Tampilan</label>
          <input type="text" value={displayName} onChange={e => setDisplayName(e.target.value)} maxLength={32}
            onBlur={() => setTouched(p => ({ ...p, name: true }))}
            style={{ ...inputBase, height: '56px', padding: '0 16px', border: `1.5px solid ${nameErr ? '#E07B65' : '#D6CBBF'}`, boxShadow: nameErr ? '0 0 0 3px rgba(224,123,101,0.1)' : 'none' }} />
          <div className="flex items-center justify-between mt-2">
            <AnimatePresence>
              {nameErr && <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="flex items-center gap-1"><AlertCircle size={12} color="#E07B65" /><span style={{ color: '#E07B65', fontSize: '12px' }}>{nameErr}</span></motion.div>}
            </AnimatePresence>
            <span style={{ color: '#C4D0CE', fontSize: '11px', marginLeft: 'auto' }}>{displayName.length}/32</span>
          </div>
        </div>

        {/* Username */}
        <div className="mb-4">
          <label style={{ color: userErr ? '#E07B65' : '#4A706B', fontSize: '13px', fontWeight: 600, display: 'block', marginBottom: '8px' }}>Username</label>
          <div className="relative">
            <span style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#9EAEAD', fontSize: '15px', pointerEvents: 'none' }}>@</span>
            <input type="text" value={username} onChange={e => setUsername(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))} maxLength={20}
              onBlur={() => setTouched(p => ({ ...p, username: true }))}
              style={{ ...inputBase, height: '56px', paddingLeft: '30px', paddingRight: '16px', border: `1.5px solid ${userErr ? '#E07B65' : '#D6CBBF'}`, boxShadow: userErr ? '0 0 0 3px rgba(224,123,101,0.1)' : 'none' }} />
          </div>
          <div className="flex items-center justify-between mt-2">
            <AnimatePresence>
              {userErr
                ? <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="flex items-center gap-1"><AlertCircle size={12} color="#E07B65" /><span style={{ color: '#E07B65', fontSize: '12px' }}>{userErr}</span></motion.div>
                : <span style={{ color: '#C4D0CE', fontSize: '11px' }}>Huruf kecil, angka, dan underscore</span>
              }
            </AnimatePresence>
            <span style={{ color: '#C4D0CE', fontSize: '11px', marginLeft: 'auto' }}>{username.length}/20</span>
          </div>
        </div>

        {/* Bio */}
        <div className="mb-6">
          <label style={{ color: '#4A706B', fontSize: '13px', fontWeight: 600, display: 'block', marginBottom: '8px' }}>Bio</label>
          <textarea value={bio} onChange={e => setBio(e.target.value)} maxLength={120} rows={3}
            style={{ ...inputBase, padding: '14px 16px', border: '1.5px solid #D6CBBF', resize: 'none', height: '96px' } as React.CSSProperties} />
          <div className="flex justify-end mt-1">
            <span style={{ color: bio.length > 100 ? '#E07B65' : '#C4D0CE', fontSize: '11px' }}>{bio.length}/120</span>
          </div>
        </div>

        {/* Info */}
        <div style={{ padding: '13px 16px', borderRadius: '12px', background: 'rgba(151,179,174,0.08)', border: '1px solid rgba(151,179,174,0.3)' }}>
          <p style={{ color: '#4A706B', fontSize: '13px', fontWeight: 600, marginBottom: '3px' }}>Ubah Email & Password</p>
          <p style={{ color: '#9EAEAD', fontSize: '12px', lineHeight: 1.5 }}>
            Pergi ke <span style={{ color: '#97B3AE', fontWeight: 600, cursor: 'pointer' }} onClick={() => navigate('/settings')}>Pengaturan</span> untuk mengubah email atau password.
          </p>
        </div>
      </div>

      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  );
}
