import { useState, useRef } from 'react';
import { useNavigate } from 'react-router';
import { X, Zap, SwitchCamera, Upload, CheckCircle2, Camera, RotateCcw, Grid3x3 } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

const CAPTURED_IMG = 'https://images.unsplash.com/photo-1753469805532-537f677c27b4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaXJjdWxhciUyMHJvdW5kJTIwc2hhcGVzJTIwcGhvdG9ncmFwaHl8ZW58MXx8fHwxNzc3MDMzNzA5fDA&ixlib=rb-4.1.0&q=80&w=1080';
const BG_IMG       = 'https://images.unsplash.com/photo-1544730786-12cad2dccc97?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhYnN0cmFjdCUyMGxpZ2h0JTIwYm9rZWglMjBkYXJrfGVufDF8fHx8MTc3NzAzMzcxMXww&ixlib=rb-4.1.0&q=80&w=1080';

type Stage = 'viewfinder' | 'preview' | 'submitting' | 'done';

export function CameraScreen() {
  const navigate = useNavigate();
  const [stage,     setStage]     = useState<Stage>('viewfinder');
  const [caption,   setCaption]   = useState('');
  const [flash,     setFlash]     = useState(false);
  const [flashOn,   setFlashOn]   = useState(false);
  const [showGrid,  setShowGrid]  = useState(true);
  const [progress,  setProgress]  = useState(0);
  const progressRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const handleCapture = () => {
    if (flashOn) { setFlash(true); setTimeout(() => setFlash(false), 150); }
    else { setFlash(true); setTimeout(() => setFlash(false), 80); }
    setTimeout(() => setStage('preview'), 200);
  };

  const handleSubmit = () => {
    setStage('submitting');
    setProgress(0);
    progressRef.current = setInterval(() => {
      setProgress(prev => {
        if (prev >= 100) {
          clearInterval(progressRef.current!);
          setStage('done');
          return 100;
        }
        return prev + 4;
      });
    }, 50);
  };

  if (stage === 'done') {
    return (
      <div className="flex flex-col items-center justify-center gap-5" style={{ height: '800px', background: '#F0EEEA' }}>
        <motion.div initial={{ scale: 0, rotate: -20 }} animate={{ scale: 1, rotate: 0 }} transition={{ type: 'spring', stiffness: 200, damping: 14 }}>
          <div style={{ width: '88px', height: '88px', borderRadius: '50%', background: 'rgba(151,179,174,0.15)', border: '2.5px solid #97B3AE', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 0 0 12px rgba(151,179,174,0.08)' }}>
            <CheckCircle2 size={42} color="#97B3AE" />
          </div>
        </motion.div>
        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="text-center">
          <h2 style={{ color: '#2C3A37', fontSize: '24px', fontWeight: 800, marginBottom: '6px' }}>Foto Terkirim!</h2>
          <p style={{ color: '#9EAEAD', fontSize: '14px' }}>Foto kamu sudah masuk ke community feed</p>
        </motion.div>
        <motion.div initial={{ opacity: 0, scale: 0.8 }} animate={{ opacity: 1, scale: 1 }} transition={{ delay: 0.45 }}
          style={{ padding: '8px 20px', borderRadius: '20px', background: 'rgba(151,179,174,0.12)', border: '1px solid rgba(151,179,174,0.4)', color: '#4A706B', fontSize: '14px', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '6px' }}>
          <Zap size={14} color="#4A706B" fill="#4A706B" />
          +10 XP diperoleh!
        </motion.div>
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.6 }} className="flex gap-3">
          <button onClick={() => navigate('/feed')}
            style={{ padding: '12px 20px', borderRadius: '12px', background: '#97B3AE', border: 'none', color: 'white', fontSize: '14px', fontWeight: 700, cursor: 'pointer', boxShadow: '0 4px 16px rgba(151,179,174,0.4)' }}>
            Lihat Feed
          </button>
          <button onClick={() => navigate('/home')}
            style={{ padding: '12px 20px', borderRadius: '12px', background: 'white', border: '1.5px solid #E8E0D8', color: '#627370', fontSize: '14px', fontWeight: 600, cursor: 'pointer' }}>
            Ke Home
          </button>
        </motion.div>
      </div>
    );
  }

  return (
    <div style={{ height: '800px', background: 'black', position: 'relative', overflow: 'hidden' }}>
      {/* Viewfinder BG */}
      <img src={BG_IMG} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', opacity: stage === 'preview' ? 0.25 : 0.75, filter: stage === 'preview' ? 'blur(6px) saturate(0.5)' : 'none', transition: 'all 0.4s', position: 'absolute', inset: 0 }} />

      {/* Flash effect */}
      <AnimatePresence>
        {flash && (
          <motion.div initial={{ opacity: 0.95 }} animate={{ opacity: 0 }} transition={{ duration: 0.18 }}
            style={{ position: 'absolute', inset: 0, background: 'white', zIndex: 50 }} />
        )}
      </AnimatePresence>

      {/* Challenge banner */}
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, padding: '12px 16px', background: 'linear-gradient(to bottom, rgba(0,0,0,0.6), transparent)', zIndex: 10 }}>
        <div style={{ padding: '7px 14px', borderRadius: '20px', background: 'rgba(151,179,174,0.88)', backdropFilter: 'blur(8px)', display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
          <Camera size={12} color="white" />
          <span style={{ color: 'white', fontSize: '12px', fontWeight: 600 }}>Foto sesuatu berbentuk lingkaran</span>
        </div>
      </div>

      {/* Top controls */}
      <div className="absolute flex items-center justify-between px-4" style={{ top: '60px', left: 0, right: 0, zIndex: 10 }}>
        <button onClick={() => navigate(-1)}
          style={{ width: '44px', height: '44px', borderRadius: '50%', background: 'rgba(0,0,0,0.45)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          <X size={20} color="white" />
        </button>
        <div className="flex gap-3">
          <button onClick={() => setFlashOn(!flashOn)}
            style={{ width: '44px', height: '44px', borderRadius: '50%', background: flashOn ? 'rgba(242,195,185,0.5)' : 'rgba(0,0,0,0.45)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', transition: 'background 0.2s' }}>
            <Zap size={18} color="white" fill={flashOn ? 'white' : 'none'} />
          </button>
          <button onClick={() => setShowGrid(!showGrid)}
            style={{ width: '44px', height: '44px', borderRadius: '50%', background: showGrid ? 'rgba(151,179,174,0.5)' : 'rgba(0,0,0,0.45)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', transition: 'background 0.2s' }}>
            <Grid3x3 size={16} color="white" />
          </button>
        </div>
      </div>

      {/* Grid overlay */}
      {showGrid && stage === 'viewfinder' && (
        <div style={{ position: 'absolute', inset: 0, zIndex: 5, backgroundImage: 'linear-gradient(rgba(255,255,255,0.07) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.07) 1px, transparent 1px)', backgroundSize: '33.33% 33.33%', pointerEvents: 'none' }} />
      )}

      {/* Photo preview */}
      <AnimatePresence>
        {(stage === 'preview' || stage === 'submitting') && (
          <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.9 }}
            style={{ position: 'absolute', top: '110px', left: '20px', right: '20px', zIndex: 20 }}>
            <div style={{ borderRadius: '18px', overflow: 'hidden', border: '3px solid rgba(255,255,255,0.55)', boxShadow: '0 16px 48px rgba(0,0,0,0.35)' }}>
              <img src={CAPTURED_IMG} alt="Captured" style={{ width: '100%', aspectRatio: '4/3', objectFit: 'cover', display: 'block' }} />
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Bottom controls */}
      <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, padding: '20px', background: 'linear-gradient(to top, rgba(0,0,0,0.9), transparent)', zIndex: 30 }}>
        {stage === 'viewfinder' ? (
          <div className="flex items-center justify-center gap-10">
            <button style={{ width: '52px', height: '52px', borderRadius: '50%', background: 'rgba(255,255,255,0.18)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
              <SwitchCamera size={22} color="white" />
            </button>
            <motion.button whileTap={{ scale: 0.88 }} onClick={handleCapture}
              style={{ width: '76px', height: '76px', borderRadius: '50%', background: 'white', border: '5px solid rgba(255,255,255,0.3)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 0 0 4px rgba(255,255,255,0.12)' }}>
              <div style={{ width: '60px', height: '60px', borderRadius: '50%', background: '#F0EEEA' }} />
            </motion.button>
            <div style={{ width: '52px' }} />
          </div>
        ) : stage === 'preview' ? (
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="flex flex-col gap-3">
            <input type="text" placeholder="Tulis caption... (opsional)" value={caption} onChange={e => setCaption(e.target.value)}
              style={{ width: '100%', height: '50px', borderRadius: '14px', background: 'rgba(255,255,255,0.12)', border: '1.5px solid rgba(255,255,255,0.28)', color: 'white', fontSize: '14px', padding: '0 16px', outline: 'none', boxSizing: 'border-box', fontFamily: "'Plus Jakarta Sans', sans-serif", backdropFilter: 'blur(8px)' } as React.CSSProperties} />
            <div className="flex gap-3">
              <button onClick={() => setStage('viewfinder')}
                style={{ width: '50px', height: '52px', borderRadius: '14px', background: 'rgba(255,255,255,0.12)', border: '1.5px solid rgba(255,255,255,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', flexShrink: 0 }}>
                <RotateCcw size={20} color="white" />
              </button>
              <motion.button whileTap={{ scale: 0.97 }} onClick={handleSubmit}
                className="flex-1 flex items-center justify-center gap-2"
                style={{ height: '52px', borderRadius: '14px', background: '#97B3AE', border: 'none', color: 'white', fontSize: '15px', fontWeight: 700, cursor: 'pointer', boxShadow: '0 6px 20px rgba(151,179,174,0.4)' }}>
                <Upload size={18} color="white" />
                Submit Foto
              </motion.button>
            </div>
          </motion.div>
        ) : (
          /* Submitting state */
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex flex-col items-center gap-4">
            <p style={{ color: 'white', fontSize: '15px', fontWeight: 600 }}>Mengunggah foto...</p>
            <div style={{ width: '100%', height: '6px', borderRadius: '3px', background: 'rgba(255,255,255,0.2)', overflow: 'hidden' }}>
              <motion.div animate={{ width: `${progress}%` }} transition={{ duration: 0.05 }}
                style={{ height: '100%', borderRadius: '3px', background: '#97B3AE', transition: 'width 0.05s linear' }} />
            </div>
            <p style={{ color: 'rgba(255,255,255,0.5)', fontSize: '13px' }}>{progress}%</p>
          </motion.div>
        )}
      </div>
    </div>
  );
}
