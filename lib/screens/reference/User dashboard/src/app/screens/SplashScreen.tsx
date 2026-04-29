import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router';
import { Camera, Zap, Gamepad2, Star } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

const FEATURES = [
  { icon: Camera, label: '47 tantangan aktif' },
  { icon: Star,   label: '12K+ fotografer' },
  { icon: Zap,    label: 'Reward harian' },
];

export function SplashScreen() {
  const navigate = useNavigate();
  const [step, setStep] = useState(0); // 0=loading, 1=ready

  useEffect(() => {
    const t = setTimeout(() => setStep(1), 600);
    return () => clearTimeout(t);
  }, []);

  return (
    <div
      className="relative flex flex-col items-center overflow-hidden"
      style={{ height: '800px', background: 'linear-gradient(170deg, #D2E0D3 0%, #F0DDD6 55%, #F0EEEA 100%)' }}
    >
      {/* Background blobs */}
      <div className="absolute top-0 right-0 pointer-events-none" style={{ width: '280px', height: '280px', background: 'rgba(242,195,185,0.38)', filter: 'blur(80px)', borderRadius: '50%' }} />
      <div className="absolute bottom-48 -left-16 pointer-events-none" style={{ width: '220px', height: '220px', background: 'rgba(151,179,174,0.28)', filter: 'blur(70px)', borderRadius: '50%' }} />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none" style={{ width: '350px', height: '350px', background: 'rgba(214,203,191,0.15)', filter: 'blur(90px)', borderRadius: '50%' }} />

      {/* Dot grid */}
      <div className="absolute inset-0 pointer-events-none" style={{ backgroundImage: 'radial-gradient(circle, rgba(74,112,107,0.08) 1px, transparent 1px)', backgroundSize: '28px 28px' }} />

      <div className="flex flex-col items-center justify-center flex-1 w-full px-8">
        <AnimatePresence>
          {step >= 1 && (
            <>
              {/* Logo */}
              <motion.div
                key="logo"
                initial={{ scale: 0.2, opacity: 0, rotate: -20 }}
                animate={{ scale: 1, opacity: 1, rotate: 0 }}
                transition={{ type: 'spring', stiffness: 200, damping: 18 }}
                className="relative mb-6"
              >
                <div style={{ width: '120px', height: '120px', borderRadius: '36px', background: '#97B3AE', boxShadow: '0 24px 64px rgba(151,179,174,0.5), 0 0 0 1px rgba(255,255,255,0.45)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Camera size={54} color="white" strokeWidth={1.4} />
                </div>
                <motion.div
                  initial={{ scale: 0, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  transition={{ delay: 0.4, type: 'spring', stiffness: 300 }}
                  style={{ position: 'absolute', top: '-10px', right: '-10px', width: '36px', height: '36px', borderRadius: '50%', background: '#F2C3B9', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 16px rgba(242,195,185,0.7)', border: '2.5px solid #F0EEEA' }}
                >
                  <Zap size={17} color="white" fill="white" />
                </motion.div>
              </motion.div>

              {/* Title */}
              <motion.div
                key="title"
                initial={{ opacity: 0, y: 24 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.25, duration: 0.5 }}
                className="text-center mb-3"
              >
                <h1 style={{ color: '#2C3A37', fontSize: '52px', fontWeight: 900, letterSpacing: '-2.5px', lineHeight: 1, marginBottom: '12px' }}>
                  SnapQuest
                </h1>
                <p style={{ color: '#627370', fontSize: '16px', fontWeight: 400, lineHeight: 1.7 }}>
                  Satu foto. Satu tantangan.
                  <br />Setiap hari.
                </p>
              </motion.div>

              {/* Divider */}
              <motion.div
                key="divider"
                initial={{ scaleX: 0, opacity: 0 }}
                animate={{ scaleX: 1, opacity: 1 }}
                transition={{ delay: 0.45, duration: 0.5 }}
                style={{ width: '48px', height: '3px', borderRadius: '2px', background: 'linear-gradient(90deg, #97B3AE, #F2C3B9)', marginBottom: '28px' }}
              />

              {/* Feature chips */}
              <motion.div
                key="chips"
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5, duration: 0.4 }}
                className="flex gap-3 mb-10"
              >
                {FEATURES.map(({ icon: Icon, label }, i) => (
                  <motion.div
                    key={label}
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: 0.55 + i * 0.08 }}
                    style={{ padding: '6px 12px', borderRadius: '20px', background: 'rgba(255,255,255,0.65)', border: '1px solid rgba(151,179,174,0.25)', backdropFilter: 'blur(8px)', display: 'flex', alignItems: 'center', gap: '5px' }}
                  >
                    <Icon size={12} color="#4A706B" />
                    <span style={{ color: '#4A706B', fontSize: '11px', fontWeight: 600, whiteSpace: 'nowrap' }}>{label}</span>
                  </motion.div>
                ))}
              </motion.div>

              {/* CTAs */}
              <motion.div
                key="cta"
                initial={{ opacity: 0, y: 32 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.6, duration: 0.45 }}
                className="w-full flex flex-col gap-3"
              >
                <motion.button
                  whileTap={{ scale: 0.97 }}
                  onClick={() => navigate('/register')}
                  className="w-full flex items-center justify-center gap-2"
                  style={{ height: '58px', borderRadius: '16px', background: '#97B3AE', color: 'white', fontSize: '17px', fontWeight: 700, border: 'none', cursor: 'pointer', boxShadow: '0 10px 36px rgba(151,179,174,0.48)' }}
                >
                  <Gamepad2 size={20} color="white" />
                  Mulai Bermain
                </motion.button>
                <motion.button
                  whileTap={{ scale: 0.97 }}
                  onClick={() => navigate('/login')}
                  className="w-full flex items-center justify-center"
                  style={{ height: '52px', borderRadius: '16px', background: 'rgba(255,255,255,0.7)', color: '#4A706B', fontSize: '15px', fontWeight: 700, border: '1.5px solid rgba(151,179,174,0.35)', cursor: 'pointer', backdropFilter: 'blur(8px)' }}
                >
                  Sudah punya akun? Masuk
                </motion.button>
              </motion.div>
            </>
          )}
        </AnimatePresence>

        {step === 0 && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            style={{ width: '40px', height: '40px', borderRadius: '50%', border: '3px solid rgba(151,179,174,0.3)', borderTop: '3px solid #97B3AE', animation: 'spin 0.8s linear infinite' }}
          />
        )}
      </div>

      <p style={{ color: 'rgba(100,130,125,0.4)', fontSize: '11px', paddingBottom: '20px' }}>
        SnapQuest v1.2.0 · Daily Photo Challenge
      </p>

      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  );
}
