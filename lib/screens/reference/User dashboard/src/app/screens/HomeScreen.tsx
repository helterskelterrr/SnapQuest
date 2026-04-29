import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router';
import { Bell, Star, Clock, CheckCircle2, Circle, ChevronRight, Trophy, Camera, Heart, ThumbsUp, Award, Flame, Zap, TrendingUp } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Toast } from '../components/Toast';

const CIRCULAR_IMG = 'https://images.unsplash.com/photo-1753469805532-537f677c27b4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaXJjdWxhciUyMHJvdW5kJTIwc2hhcGVzJTIwcGhvdG9ncmFwaHl8ZW58MXx8fHwxNzc3MDMzNzA5fDA&ixlib=rb-4.1.0&q=80&w=1080';
const PORTRAIT_IMG = 'https://images.unsplash.com/photo-1554454188-f84071b1695f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwb3J0cmFpdCUyMHBlcnNvbiUyMHNtaWxpbmclMjBwaG90b2dyYXBoeXxlbnwxfHx8fDE3NzcwMzM3MTF8MA&ixlib=rb-4.1.0&q=80&w=1080';
const SUBMITTED_IMG = 'https://images.unsplash.com/photo-1556620286-5e892be0cfbb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2xvcmZ1bCUyMHN0cmVldCUyMHBob3RvZ3JhcGh5JTIwdXJiYW58ZW58MXx8fHwxNzc3MDMzNzEwfDA&ixlib=rb-4.1.0&q=80&w=1080';

function useGreeting() {
  const h = new Date().getHours();
  if (h < 12) return 'Selamat Pagi';
  if (h < 17) return 'Selamat Siang';
  if (h < 20) return 'Selamat Sore';
  return 'Selamat Malam';
}

function Countdown() {
  const [time, setTime] = useState({ h: 14, m: 22, s: 0 });
  useEffect(() => {
    const id = setInterval(() => {
      setTime((prev) => {
        let { h, m, s } = prev;
        if (--s < 0) { s = 59; if (--m < 0) { m = 59; h = h > 0 ? h - 1 : 23; } }
        return { h, m, s };
      });
    }, 1000);
    return () => clearInterval(id);
  }, []);
  const pad = (n: number) => String(n).padStart(2, '0');
  const urgent = time.h === 0 && time.m < 30;
  return (
    <div className="flex items-center gap-2">
      <motion.div animate={urgent ? { scale: [1, 1.15, 1] } : {}} transition={{ repeat: Infinity, duration: 1.5 }}>
        <Clock size={13} color={urgent ? '#E07B65' : '#97B3AE'} />
      </motion.div>
      <span style={{ color: urgent ? '#E07B65' : '#627370', fontSize: '13px', fontWeight: 600 }}>
        Berakhir dalam {pad(time.h)}:{pad(time.m)}:{pad(time.s)}
      </span>
    </div>
  );
}

const STREAK_DAYS = [true, true, true, true, true, false, false]; // Mon-Sun

function StreakDots() {
  const days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
  return (
    <div className="flex items-center gap-1.5">
      {STREAK_DAYS.map((done, i) => (
        <div key={i} className="flex flex-col items-center gap-1">
          <div style={{ width: '26px', height: '26px', borderRadius: '8px', background: done ? '#97B3AE' : '#F0EEEA', border: `1.5px solid ${done ? '#97B3AE' : '#E8E0D8'}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            {done && <CheckCircle2 size={13} color="white" />}
          </div>
          <span style={{ color: done ? '#4A706B' : '#C4D0CE', fontSize: '9px', fontWeight: 600 }}>{days[i]}</span>
        </div>
      ))}
    </div>
  );
}

function SectionLabel({ children, action }: { children: React.ReactNode; action?: React.ReactNode }) {
  return (
    <div className="flex items-center gap-2 mb-3">
      <div style={{ width: '3px', height: '16px', borderRadius: '2px', background: 'linear-gradient(to bottom, #97B3AE, #D2E0D3)', flexShrink: 0 }} />
      <h3 style={{ color: '#2C3A37', fontSize: '15px', fontWeight: 700, flex: 1 }}>{children}</h3>
      {action}
    </div>
  );
}

const INITIAL_QUESTS = [
  { id: 1, done: true,  icon: Camera,   label: 'Submit foto hari ini',  xp: '+10 XP', detail: 'Sudah terupload!' },
  { id: 2, done: false, icon: Heart,    label: 'Dapat 3 vote',          xp: '+15 XP', detail: '1/3 vote diterima' },
  { id: 3, done: false, icon: ThumbsUp, label: 'Vote 5 foto orang lain', xp: '+10 XP', detail: '0/5 divote' },
];

export function HomeScreen() {
  const navigate = useNavigate();
  const greeting = useGreeting();
  const [submitted] = useState(true);
  const [quests, setQuests] = useState(INITIAL_QUESTS);
  const [toast, setToast] = useState<{ msg: string; type: 'error' | 'success' | 'info' | 'warning' } | null>(null);

  const showT = (msg: string, type: 'error' | 'success' | 'info' | 'warning' = 'info') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 2500);
  };

  const toggleQuest = (id: number) => {
    setQuests(prev => prev.map(q => {
      if (q.id !== id) return q;
      const next = { ...q, done: !q.done };
      if (next.done) showT(`${q.xp} didapat!`, 'success');
      return next;
    }));
  };

  const doneCount = quests.filter(q => q.done).length;

  return (
    <div className="overflow-y-auto relative" style={{ height: '736px', background: '#F0EEEA', scrollbarWidth: 'none' } as React.CSSProperties}>
      <AnimatePresence>{toast && <Toast message={toast.msg} type={toast.type} onDismiss={() => setToast(null)} />}</AnimatePresence>

      {/* Header */}
      <div className="flex items-center justify-between px-5 pt-5 pb-3">
        <div>
          <p style={{ color: '#B8C9C7', fontSize: '13px', fontWeight: 500 }}>{greeting}</p>
          <h2 style={{ color: '#2C3A37', fontSize: '22px', fontWeight: 800, lineHeight: 1.2 }}>Alex Prasetyo</h2>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={() => navigate('/notifications')}
            style={{ width: '44px', height: '44px', borderRadius: '12px', background: 'white', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', position: 'relative', boxShadow: '0 2px 8px rgba(44,58,55,0.07)' }}>
            <Bell size={18} color="#97B3AE" />
            <motion.div animate={{ scale: [1, 1.3, 1] }} transition={{ repeat: Infinity, duration: 2, repeatDelay: 4 }}
              style={{ position: 'absolute', top: '9px', right: '9px', width: '8px', height: '8px', borderRadius: '50%', background: '#F2C3B9', border: '1.5px solid white' }} />
          </button>
          <button onClick={() => navigate('/profile')}
            style={{ width: '44px', height: '44px', borderRadius: '50%', background: '#97B3AE', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: 800, color: 'white', border: '2px solid white', boxShadow: '0 4px 12px rgba(151,179,174,0.4)', cursor: 'pointer', position: 'relative' }}>
            AP
            <div style={{ position: 'absolute', bottom: 0, right: 0, width: '14px', height: '14px', borderRadius: '50%', background: '#F2C3B9', border: '1.5px solid white', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Flame size={8} color="white" fill="white" />
            </div>
          </button>
        </div>
      </div>

      {/* Stats row */}
      <div className="flex gap-3 px-5 mb-4">
        {[
          { icon: Star,       color: '#E07B65', fill: true,  label: 'Poin Minggu',  val: '2,840' },
          { icon: Trophy,     color: '#97B3AE', fill: false, label: 'Ranking',      val: '#12' },
          { icon: TrendingUp, color: '#4A706B', fill: false, label: 'Streak',       val: '47 hari' },
        ].map(({ icon: Icon, color, fill, label, val }) => (
          <div key={label} className="flex-1 flex items-center gap-2"
            style={{ padding: '10px 12px', borderRadius: '14px', background: 'white', border: '1.5px solid #E8E0D8', boxShadow: '0 2px 10px rgba(44,58,55,0.06)' }}>
            <Icon size={14} color={color} fill={fill ? color : 'none'} />
            <div>
              <p style={{ color: '#B8C9C7', fontSize: '10px' }}>{label}</p>
              <p style={{ color: '#2C3A37', fontSize: '14px', fontWeight: 800, lineHeight: 1.1 }}>{val}</p>
            </div>
          </div>
        ))}
      </div>

      {/* XP Bar */}
      <div className="px-5 mb-4">
        <div style={{ padding: '12px 16px', borderRadius: '14px', background: 'white', border: '1.5px solid #E8E0D8', boxShadow: '0 2px 10px rgba(44,58,55,0.06)' }}>
          <div className="flex justify-between items-center mb-2">
            <div className="flex items-center gap-1.5">
              <Zap size={12} color="#97B3AE" fill="#97B3AE" />
              <span style={{ color: '#627370', fontSize: '12px', fontWeight: 600 }}>Rising Shooter</span>
              <span style={{ color: '#C4D0CE', fontSize: '11px' }}>→ Sharp Eye</span>
            </div>
            <span style={{ color: '#4A706B', fontSize: '12px', fontWeight: 700, background: 'rgba(151,179,174,0.12)', padding: '2px 8px', borderRadius: '20px' }}>340 / 500 XP</span>
          </div>
          <div style={{ height: '6px', borderRadius: '3px', background: '#F0EEEA', overflow: 'hidden' }}>
            <motion.div initial={{ width: 0 }} animate={{ width: '68%' }} transition={{ duration: 1.2, delay: 0.3, ease: 'easeOut' }}
              style={{ height: '100%', borderRadius: '3px', background: 'linear-gradient(90deg, #97B3AE, #D2E0D3)' }} />
          </div>
          <p style={{ color: '#C4D0CE', fontSize: '10px', marginTop: '4px' }}>160 XP lagi untuk naik level</p>
        </div>
      </div>

      {/* Challenge Card */}
      <div className="px-5 mb-4">
        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }}
          style={{ borderRadius: '20px', background: 'white', border: '1.5px solid #E8E0D8', overflow: 'hidden', boxShadow: '0 4px 20px rgba(44,58,55,0.08)' }}>
          <div style={{ position: 'relative', height: '140px', overflow: 'hidden' }}>
            <img src={CIRCULAR_IMG} alt="Challenge" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
            <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to bottom, rgba(151,179,174,0.1) 0%, rgba(240,238,234,0.88) 100%)' }} />
            <div style={{ position: 'absolute', top: '12px', left: '12px', padding: '4px 10px', borderRadius: '20px', background: 'rgba(151,179,174,0.9)', backdropFilter: 'blur(4px)', display: 'inline-flex', alignItems: 'center', gap: '5px' }}>
              <Camera size={11} color="white" />
              <span style={{ color: 'white', fontSize: '11px', fontWeight: 600 }}>Tantangan Hari Ini</span>
            </div>
          </div>
          <div style={{ padding: '16px' }}>
            <h2 style={{ color: '#2C3A37', fontSize: '22px', fontWeight: 800, lineHeight: 1.2, marginBottom: '6px' }}>Foto sesuatu<br />berbentuk lingkaran</h2>
            <p style={{ color: '#9EAEAD', fontSize: '13px', marginBottom: '12px', lineHeight: 1.5 }}>
              Temukan objek berbentuk lingkaran di sekitarmu — ban, piring, jam, atau apa saja!
            </p>
            <Countdown />
            <div style={{ marginTop: '14px' }}>
              {submitted ? (
                <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}
                  className="flex items-center gap-3"
                  style={{ padding: '10px 14px', borderRadius: '12px', background: 'rgba(151,179,174,0.08)', border: '1.5px solid rgba(151,179,174,0.35)', cursor: 'pointer' }}
                  onClick={() => navigate('/post/1')}>
                  <div style={{ width: '44px', height: '44px', borderRadius: '8px', overflow: 'hidden', flexShrink: 0, border: '2px solid rgba(151,179,174,0.4)' }}>
                    <img src={SUBMITTED_IMG} alt="Submitted" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-1.5">
                      <CheckCircle2 size={15} color="#4A706B" />
                      <span style={{ color: '#4A706B', fontSize: '14px', fontWeight: 700 }}>Sudah Submit!</span>
                    </div>
                    <p style={{ color: '#9EAEAD', fontSize: '11px', marginTop: '2px' }}>Tap untuk lihat foto kamu di feed</p>
                  </div>
                  <ChevronRight size={16} color="#C4D0CE" />
                </motion.div>
              ) : (
                <motion.button whileTap={{ scale: 0.97 }} onClick={() => navigate('/camera')} className="w-full flex items-center justify-center gap-2"
                  style={{ height: '52px', borderRadius: '12px', background: '#97B3AE', color: 'white', fontSize: '15px', fontWeight: 700, border: 'none', cursor: 'pointer', boxShadow: '0 6px 20px rgba(151,179,174,0.4)' }}>
                  <Camera size={18} color="white" />
                  Ambil Foto Sekarang
                </motion.button>
              )}
            </div>
          </div>
        </motion.div>
      </div>

      {/* Streak Week */}
      <div className="px-5 mb-4">
        <SectionLabel>
          <span className="flex items-center gap-2">
            <Flame size={15} color="#E07B65" fill="#E07B65" />
            Streak 47 Hari
          </span>
        </SectionLabel>
        <div style={{ padding: '14px 16px', borderRadius: '14px', background: 'white', border: '1.5px solid #E8E0D8', boxShadow: '0 2px 10px rgba(44,58,55,0.06)' }}>
          <StreakDots />
          <p style={{ color: '#B8C9C7', fontSize: '11px', marginTop: '8px' }}>5/7 hari minggu ini · Jangan putus sekarang!</p>
        </div>
      </div>

      {/* Daily Quests */}
      <div className="px-5 mb-4">
        <SectionLabel action={<span style={{ color: '#97B3AE', fontSize: '12px', fontWeight: 600 }}>{doneCount}/{quests.length} selesai</span>}>
          Quest Harian
        </SectionLabel>
        <div style={{ borderRadius: '16px', background: 'white', border: '1.5px solid #E8E0D8', overflow: 'hidden', boxShadow: '0 2px 10px rgba(44,58,55,0.06)' }}>
          {quests.map((q, i) => {
            const Icon = q.icon;
            return (
              <motion.button key={q.id} whileTap={{ scale: 0.98 }} onClick={() => toggleQuest(q.id)} className="flex items-center gap-3 px-4 py-3 w-full"
                style={{ borderBottom: i < quests.length - 1 ? '1px solid #F0EEEA' : 'none', background: q.done ? 'rgba(151,179,174,0.05)' : 'white', border: 'none', cursor: 'pointer', textAlign: 'left' }}>
                <motion.div animate={{ scale: q.done ? [1, 1.3, 1] : 1 }} transition={{ duration: 0.3 }}>
                  {q.done ? <CheckCircle2 size={20} color="#97B3AE" /> : <Circle size={20} color="#D6CBBF" />}
                </motion.div>
                <Icon size={15} color={q.done ? '#C4D0CE' : '#4A706B'} />
                <div className="flex-1 text-left">
                  <p style={{ color: q.done ? '#B8C9C7' : '#2C3A37', fontSize: '13px', fontWeight: 500, textDecoration: q.done ? 'line-through' : 'none' }}>{q.label}</p>
                  <p style={{ color: '#C4D0CE', fontSize: '11px', marginTop: '1px' }}>{q.detail}</p>
                </div>
                <span style={{ color: q.done ? '#97B3AE' : '#E07B65', fontSize: '12px', fontWeight: 700, background: q.done ? 'rgba(151,179,174,0.1)' : 'rgba(242,195,185,0.25)', padding: '2px 8px', borderRadius: '20px', flexShrink: 0 }}>{q.xp}</span>
              </motion.button>
            );
          })}
        </div>
      </div>

      {/* Photo of the Day */}
      <div className="px-5 pb-6">
        <SectionLabel action={
          <button onClick={() => navigate('/feed')} style={{ background: 'transparent', border: 'none', color: '#97B3AE', fontSize: '12px', fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '2px', padding: '4px' }}>
            Lihat semua <ChevronRight size={14} />
          </button>
        }>Photo of the Day</SectionLabel>
        <motion.div whileTap={{ scale: 0.99 }} onClick={() => navigate('/post/2')}
          style={{ borderRadius: '16px', overflow: 'hidden', border: '1.5px solid #E8E0D8', background: 'white', boxShadow: '0 2px 10px rgba(44,58,55,0.06)', cursor: 'pointer' }}>
          <div style={{ position: 'relative' }}>
            <img src={PORTRAIT_IMG} alt="Photo of the Day" style={{ width: '100%', height: '180px', objectFit: 'cover' }} />
            <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to top, rgba(44,58,55,0.2) 0%, transparent 60%)' }} />
            <div style={{ position: 'absolute', top: '10px', left: '10px', padding: '4px 10px', borderRadius: '20px', background: '#F2C3B9', display: 'inline-flex', alignItems: 'center', gap: '5px' }}>
              <Award size={11} color="white" />
              <span style={{ color: 'white', fontSize: '11px', fontWeight: 700 }}>Pemenang Kemarin</span>
            </div>
          </div>
          <div className="flex items-center justify-between px-4 py-3">
            <div className="flex items-center gap-2">
              <div style={{ width: '34px', height: '34px', borderRadius: '50%', background: '#D2E0D3', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '11px', fontWeight: 800, color: '#4A706B' }}>BF</div>
              <div>
                <p style={{ color: '#2C3A37', fontSize: '13px', fontWeight: 600 }}>budi_foto</p>
                <p style={{ color: '#B8C9C7', fontSize: '11px' }}>Challenge: Warna Merah</p>
              </div>
            </div>
            <div className="flex items-center gap-1.5" style={{ padding: '5px 10px', borderRadius: '20px', background: 'rgba(242,195,185,0.15)', border: '1px solid rgba(242,195,185,0.4)' }}>
              <Heart size={13} color="#E07B65" fill="#E07B65" />
              <span style={{ color: '#E07B65', fontSize: '13px', fontWeight: 700 }}>247</span>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
}
