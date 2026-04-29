import { useState } from 'react';
import { useNavigate } from 'react-router';
import { ArrowLeft, User, Lock, Bell, Shield, Globe, Info, ChevronRight, LogOut, Trash2, Moon, Camera, Check } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Toast } from '../components/Toast';
import { ConfirmSheet } from '../components/ConfirmSheet';

function Toggle({ value, onChange }: { value: boolean; onChange: () => void }) {
  return (
    <motion.button onClick={onChange}
      style={{ width: '48px', height: '28px', borderRadius: '14px', border: 'none', cursor: 'pointer', background: value ? '#97B3AE' : '#E8E0D8', position: 'relative', flexShrink: 0, transition: 'background 0.25s', boxShadow: value ? '0 2px 8px rgba(151,179,174,0.4)' : 'none' }}>
      <motion.div animate={{ x: value ? 22 : 2 }} transition={{ type: 'spring', stiffness: 420, damping: 30 }}
        style={{ position: 'absolute', top: '4px', width: '20px', height: '20px', borderRadius: '50%', background: 'white', boxShadow: '0 1px 5px rgba(0,0,0,0.18)' }} />
    </motion.button>
  );
}

function SectionLabel({ children }: { children: string }) {
  return <p style={{ color: '#9EAEAD', fontSize: '11px', fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', padding: '16px 0 6px' }}>{children}</p>;
}

function RowItem({ icon: Icon, iconBg, iconColor, label, sublabel, onPress, rightEl, danger }: {
  icon: React.ElementType; iconBg: string; iconColor: string;
  label: string; sublabel?: string; onPress?: () => void;
  rightEl?: React.ReactNode; danger?: boolean;
}) {
  return (
    <motion.button whileTap={onPress ? { scale: 0.99, backgroundColor: '#F7F4F1' } : {}} onClick={onPress}
      className="flex items-center gap-3 w-full"
      style={{ padding: '13px 16px', background: 'transparent', border: 'none', cursor: onPress ? 'pointer' : 'default', textAlign: 'left', borderRadius: '4px' }}>
      <div style={{ width: '38px', height: '38px', borderRadius: '11px', background: iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        <Icon size={17} color={iconColor} />
      </div>
      <div className="flex-1 min-w-0">
        <p style={{ color: danger ? '#E07B65' : '#2C3A37', fontSize: '14px', fontWeight: 500 }}>{label}</p>
        {sublabel && <p style={{ color: '#B8C9C7', fontSize: '12px', marginTop: '1px' }}>{sublabel}</p>}
      </div>
      {rightEl ?? (onPress && <ChevronRight size={16} color="#C4D0CE" />)}
    </motion.button>
  );
}

function Divider() {
  return <div style={{ height: '1px', background: '#F5F2EF', marginLeft: '66px' }} />;
}

export function SettingsScreen() {
  const navigate = useNavigate();
  const [notifVote,     setNotifVote]     = useState(true);
  const [notifChallenge,setNotifChallenge]= useState(true);
  const [notifAchieve,  setNotifAchieve]  = useState(true);
  const [notifSystem,   setNotifSystem]   = useState(false);
  const [darkMode,      setDarkMode]      = useState(false);
  const [privateProfile,setPrivateProfile]= useState(false);
  const [confirmType,   setConfirmType]   = useState<'logout' | 'delete' | null>(null);
  const [toast, setToast] = useState<{ msg: string; type: 'success' | 'error' | 'info' | 'warning' } | null>(null);

  const showT = (msg: string, type: 'success' | 'error' | 'info' | 'warning' = 'info') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 2500);
  };

  const toggleAndToast = (label: string, val: boolean, setter: (v: boolean) => void) => {
    setter(!val);
    showT(`Notifikasi ${label} ${!val ? 'diaktifkan' : 'dinonaktifkan'}`, 'success');
  };

  const card = { borderRadius: '16px', background: 'white', border: '1.5px solid #E8E0D8', overflow: 'hidden', boxShadow: '0 2px 10px rgba(44,58,55,0.06)' };

  return (
    <div style={{ height: '800px', background: '#F0EEEA', display: 'flex', flexDirection: 'column', overflow: 'hidden', position: 'relative' }}>
      <div style={{ height: '4px', background: 'linear-gradient(90deg, #97B3AE, #F2C3B9, #D2E0D3)', flexShrink: 0 }} />
      <AnimatePresence>{toast && <Toast message={toast.msg} type={toast.type} onDismiss={() => setToast(null)} />}</AnimatePresence>

      {/* Header */}
      <div style={{ padding: '14px 20px', flexShrink: 0, background: 'white', borderBottom: '1px solid #F0EEEA' }}>
        <div className="flex items-center gap-3">
          <button onClick={() => navigate(-1)}
            style={{ width: '44px', height: '44px', borderRadius: '12px', background: '#FAFAF8', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
            <ArrowLeft size={20} color="#627370" />
          </button>
          <h2 style={{ color: '#2C3A37', fontSize: '20px', fontWeight: 800 }}>Pengaturan</h2>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-5 pb-6" style={{ scrollbarWidth: 'none' } as React.CSSProperties}>

        <SectionLabel>Akun</SectionLabel>
        <div style={card}>
          <RowItem icon={User}   iconBg="#D2E0D3" iconColor="#4A706B" label="Edit Profil"    sublabel="Ubah nama, username, avatar"  onPress={() => navigate('/profile/edit')} />
          <Divider />
          <RowItem icon={Lock}   iconBg="#F0DDD6" iconColor="#8C4A36" label="Ganti Password" sublabel="Terakhir diubah 3 bulan lalu"  onPress={() => showT('Fitur ini akan segera hadir', 'info')} />
          <Divider />
          <RowItem icon={Camera} iconBg="#D6CBBF" iconColor="#5E4A36" label="Email"          sublabel="alex@email.com"               onPress={() => showT('Fitur ini akan segera hadir', 'info')} />
        </div>

        <SectionLabel>Notifikasi</SectionLabel>
        <div style={card}>
          <RowItem icon={Bell}   iconBg="#D2E0D3" iconColor="#4A706B" label="Vote Diterima"  sublabel="Saat foto kamu divote"                rightEl={<Toggle value={notifVote}      onChange={() => toggleAndToast('vote', notifVote, setNotifVote)} />} />
          <Divider />
          <RowItem icon={Camera} iconBg="#F2C3B9" iconColor="#8C4A36" label="Challenge Baru" sublabel="Saat tantangan harian dimulai"         rightEl={<Toggle value={notifChallenge} onChange={() => toggleAndToast('challenge', notifChallenge, setNotifChallenge)} />} />
          <Divider />
          <RowItem icon={Bell}   iconBg="#F0DDD6" iconColor="#8C4A36" label="Pencapaian"     sublabel="Badge dan level up"                    rightEl={<Toggle value={notifAchieve}   onChange={() => toggleAndToast('pencapaian', notifAchieve, setNotifAchieve)} />} />
          <Divider />
          <RowItem icon={Bell}   iconBg="#D6CBBF" iconColor="#627370" label="Sistem"         sublabel="Update dan pengumuman"                  rightEl={<Toggle value={notifSystem}    onChange={() => toggleAndToast('sistem', notifSystem, setNotifSystem)} />} />
        </div>

        <SectionLabel>Privasi</SectionLabel>
        <div style={card}>
          <RowItem icon={Shield} iconBg="#D2E0D3" iconColor="#4A706B" label="Profil Privat"  sublabel="Hanya follower yang bisa lihat"  rightEl={<Toggle value={privateProfile} onChange={() => { setPrivateProfile(!privateProfile); showT(`Profil ${!privateProfile ? 'diprivatkan' : 'dipublikkan'}`, 'success'); }} />} />
          <Divider />
          <RowItem icon={Shield} iconBg="#D6CBBF" iconColor="#5E4A36" label="Data & Privasi" sublabel="Kelola data akunmu"               onPress={() => showT('Fitur ini akan segera hadir', 'info')} />
        </div>

        <SectionLabel>Tampilan</SectionLabel>
        <div style={card}>
          <RowItem icon={Moon}   iconBg="#D6CBBF" iconColor="#5E4A36" label="Mode Gelap"     sublabel="Aktifkan dark mode"            rightEl={<Toggle value={darkMode} onChange={() => { setDarkMode(!darkMode); showT('Fitur dark mode akan segera hadir!', 'info'); }} />} />
          <Divider />
          <RowItem icon={Globe}  iconBg="#D2E0D3" iconColor="#4A706B" label="Bahasa"         sublabel="Bahasa Indonesia"               onPress={() => showT('Bahasa lain akan segera hadir', 'info')}
            rightEl={
              <div className="flex items-center gap-1.5">
                <span style={{ color: '#B8C9C7', fontSize: '13px' }}>ID</span>
                <ChevronRight size={15} color="#C4D0CE" />
              </div>
            }
          />
        </div>

        <SectionLabel>Tentang</SectionLabel>
        <div style={card}>
          <RowItem icon={Info}   iconBg="#F0DDD6" iconColor="#8C4A36" label="Syarat & Ketentuan"  onPress={() => showT('Sedang membuka...', 'info')} />
          <Divider />
          <RowItem icon={Info}   iconBg="#F0DDD6" iconColor="#8C4A36" label="Kebijakan Privasi"   onPress={() => showT('Sedang membuka...', 'info')} />
          <Divider />
          <RowItem icon={Check}  iconBg="#D2E0D3" iconColor="#4A706B" label="Versi Aplikasi"      sublabel="SnapQuest v1.2.0 · Terbaru" />
        </div>

        <SectionLabel>Zona Berbahaya</SectionLabel>
        <div style={card}>
          <RowItem icon={LogOut} iconBg="#F0DDD6" iconColor="#E07B65" label="Keluar dari Akun" danger onPress={() => setConfirmType('logout')} />
          <Divider />
          <RowItem icon={Trash2} iconBg="rgba(224,123,101,0.1)" iconColor="#E07B65" label="Hapus Akun" sublabel="Tindakan ini tidak bisa dibatalkan" danger onPress={() => setConfirmType('delete')} />
        </div>

        <div style={{ height: '20px' }} />
      </div>

      <ConfirmSheet
        open={confirmType === 'logout'}
        title="Keluar dari Akun?"
        body="Kamu perlu login kembali untuk mengakses SnapQuest."
        confirmLabel="Ya, Keluar"
        danger
        onConfirm={() => { setConfirmType(null); navigate('/'); }}
        onCancel={() => setConfirmType(null)}
      />
      <ConfirmSheet
        open={confirmType === 'delete'}
        title="Hapus Akun Permanen?"
        body="Semua data, foto, dan pencapaianmu akan terhapus selamanya. Tindakan ini tidak bisa dibatalkan."
        confirmLabel="Hapus Selamanya"
        danger
        onConfirm={() => { setConfirmType(null); showT('Permintaan penghapusan dikirim', 'info'); }}
        onCancel={() => setConfirmType(null)}
      />
    </div>
  );
}
