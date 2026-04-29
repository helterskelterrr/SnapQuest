import { useState } from 'react';
import { useNavigate } from 'react-router';
import { ArrowLeft, Star, Grid3x3, List, Heart, Camera, Trophy, SlidersHorizontal } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

const IMGS = {
  C: 'https://images.unsplash.com/photo-1753469805532-537f677c27b4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaXJjdWxhciUyMHJvdW5kJTIwc2hhcGVzJTIwcGhvdG9ncmFwaHl8ZW58MXx8fHwxNzc3MDMzNzA5fDA&ixlib=rb-4.1.0&q=80&w=1080',
  S: 'https://images.unsplash.com/photo-1556620286-5e892be0cfbb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2xvcmZ1bCUyMHN0cmVldCUyMHBob3RvZ3JhcGh5JTIwdXJiYW58ZW58MXx8fHwxNzc3MDMzNzEwfDA&ixlib=rb-4.1.0&q=80&w=1080',
  N: 'https://images.unsplash.com/photo-1730626476382-5f18297a30b9?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxuYXR1cmUlMjB0ZXh0dXJlJTIwY2xvc2UlMjB1cCUyMG1hY3JvfGVufDF8fHx8MTc3NzAzMzcxMHww&ixlib=rb-4.1.0&q=80&w=1080',
  P: 'https://images.unsplash.com/photo-1554454188-f84071b1695f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwb3J0cmFpdCUyMHBlcnNvbiUyMHNtaWxpbmclMjBwaG90b2dyYXBoeXxlbnwxfHx8fDE3NzcwMzM3MTF8MA&ixlib=rb-4.1.0&q=80&w=1080',
  A: 'https://images.unsplash.com/photo-1544730786-12cad2dccc97?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhYnN0cmFjdCUyMGxpZ2h0JTIwYm9rZWglMjBkYXJrfGVufDF8fHx8MTc3NzAzMzcxMXww&ixlib=rb-4.1.0&q=80&w=1080',
};

const ALL_PHOTOS = [
  { id: '1', img: IMGS.C, votes: 42,  date: '24 Apr', challenge: 'Lingkaran',  won: false, month: 'Apr' },
  { id: '2', img: IMGS.S, votes: 89,  date: '23 Apr', challenge: 'Warna Merah',won: true,  month: 'Apr' },
  { id: '3', img: IMGS.N, votes: 34,  date: '22 Apr', challenge: 'Tekstur',    won: false, month: 'Apr' },
  { id: '4', img: IMGS.P, votes: 67,  date: '21 Apr', challenge: 'Potret',     won: false, month: 'Apr' },
  { id: '5', img: IMGS.A, votes: 21,  date: '20 Apr', challenge: 'Cahaya',     won: false, month: 'Apr' },
  { id: '6', img: IMGS.C, votes: 55,  date: '19 Apr', challenge: 'Lingkaran',  won: false, month: 'Apr' },
  { id: '7', img: IMGS.S, votes: 38,  date: '18 Apr', challenge: 'Urban',      won: false, month: 'Apr' },
  { id: '8', img: IMGS.N, votes: 92,  date: '10 Mar', challenge: 'Alam',       won: true,  month: 'Mar' },
  { id: '9', img: IMGS.A, votes: 15,  date: '8 Mar',  challenge: 'Abstrak',    won: false, month: 'Mar' },
  { id: '10',img: IMGS.P, votes: 74,  date: '5 Mar',  challenge: 'Potret',     won: false, month: 'Mar' },
  { id: '11',img: IMGS.C, votes: 48,  date: '20 Feb', challenge: 'Lengkung',   won: false, month: 'Feb' },
  { id: '12',img: IMGS.S, votes: 61,  date: '15 Feb', challenge: 'Jalan',      won: false, month: 'Feb' },
];

type SortKey = 'terbaru' | 'terlama' | 'votes';

export function AllSubmissionsScreen() {
  const navigate = useNavigate();
  const [view,      setView]      = useState<'grid' | 'list'>('grid');
  const [monthFilter, setMonthFilter] = useState('Semua');
  const [sort,      setSort]      = useState<SortKey>('terbaru');
  const [showFilter,setShowFilter]= useState(false);

  const months = ['Semua', 'Apr', 'Mar', 'Feb'];
  const photos = ALL_PHOTOS
    .filter(p => monthFilter === 'Semua' || p.month === monthFilter)
    .sort((a, b) => {
      if (sort === 'votes') return b.votes - a.votes;
      if (sort === 'terlama') return 0; // keep as-is reversed
      return 0;
    });

  const totalVotes = photos.reduce((a, p) => a + p.votes, 0);
  const wins = photos.filter(p => p.won).length;
  const avgVotes = photos.length ? Math.round(totalVotes / photos.length) : 0;

  return (
    <div style={{ height: '800px', background: '#F0EEEA', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      <div style={{ height: '4px', background: 'linear-gradient(90deg, #97B3AE, #F2C3B9, #D2E0D3)', flexShrink: 0 }} />

      {/* Header */}
      <div style={{ padding: '14px 20px 10px', flexShrink: 0, background: 'white', borderBottom: '1px solid #F0EEEA' }}>
        <div className="flex items-center gap-3 mb-3">
          <button onClick={() => navigate(-1)}
            style={{ width: '44px', height: '44px', borderRadius: '12px', background: '#FAFAF8', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', flexShrink: 0 }}>
            <ArrowLeft size={20} color="#627370" />
          </button>
          <div className="flex-1">
            <h2 style={{ color: '#2C3A37', fontSize: '20px', fontWeight: 800 }}>Semua Submission</h2>
            <p style={{ color: '#9EAEAD', fontSize: '12px' }}>{photos.length} foto · avg {avgVotes} votes</p>
          </div>
          <button onClick={() => setView(view === 'grid' ? 'list' : 'grid')}
            style={{ width: '40px', height: '40px', borderRadius: '12px', background: '#FAFAF8', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
            {view === 'grid' ? <List size={18} color="#627370" /> : <Grid3x3 size={18} color="#627370" />}
          </button>
          <button onClick={() => setShowFilter(!showFilter)}
            style={{ width: '40px', height: '40px', borderRadius: '12px', background: showFilter ? '#97B3AE' : '#FAFAF8', border: `1.5px solid ${showFilter ? '#97B3AE' : '#E8E0D8'}`, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
            <SlidersHorizontal size={18} color={showFilter ? 'white' : '#627370'} />
          </button>
        </div>

        {/* Stats */}
        <div className="flex gap-2 mb-3">
          {[
            { icon: Star,   color: '#E07B65', val: `${totalVotes} votes` },
            { icon: Trophy, color: '#F2C3B9', val: `${wins} menang` },
            { icon: Camera, color: '#97B3AE', val: `${photos.length} foto` },
          ].map(({ icon: Icon, color, val }) => (
            <div key={val} style={{ padding: '5px 11px', borderRadius: '20px', background: '#F5F0EB', border: '1px solid #E8E0D8', display: 'flex', alignItems: 'center', gap: '5px' }}>
              <Icon size={12} color={color} fill={color} />
              <span style={{ color: '#4A706B', fontSize: '12px', fontWeight: 600 }}>{val}</span>
            </div>
          ))}
        </div>

        {/* Filter panel */}
        <AnimatePresence>
          {showFilter && (
            <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: 'auto', opacity: 1 }} exit={{ height: 0, opacity: 0 }} style={{ overflow: 'hidden' }}>
              <div className="pb-3">
                <p style={{ color: '#9EAEAD', fontSize: '11px', fontWeight: 700, marginBottom: '8px', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Bulan</p>
                <div className="flex gap-2 mb-3">
                  {months.map(m => (
                    <button key={m} onClick={() => setMonthFilter(m)}
                      style={{ padding: '5px 12px', borderRadius: '20px', background: monthFilter === m ? '#2C3A37' : '#F0EEEA', border: `1.5px solid ${monthFilter === m ? '#2C3A37' : '#E8E0D8'}`, color: monthFilter === m ? 'white' : '#9EAEAD', fontSize: '12px', fontWeight: 600, cursor: 'pointer', transition: 'all 0.15s' }}>
                      {m === 'Semua' ? 'Semua' : `${m} 2025`}
                    </button>
                  ))}
                </div>
                <p style={{ color: '#9EAEAD', fontSize: '11px', fontWeight: 700, marginBottom: '8px', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Urutkan</p>
                <div className="flex gap-2">
                  {([['terbaru', 'Terbaru'], ['terlama', 'Terlama'], ['votes', 'Votes Terbanyak']] as [SortKey, string][]).map(([key, label]) => (
                    <button key={key} onClick={() => setSort(key)}
                      style={{ padding: '5px 12px', borderRadius: '20px', background: sort === key ? '#97B3AE' : '#F0EEEA', border: `1.5px solid ${sort === key ? '#97B3AE' : '#E8E0D8'}`, color: sort === key ? 'white' : '#9EAEAD', fontSize: '12px', fontWeight: 600, cursor: 'pointer', transition: 'all 0.15s' }}>
                      {label}
                    </button>
                  ))}
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-5 pt-4 pb-4" style={{ scrollbarWidth: 'none' } as React.CSSProperties}>
        {view === 'grid' ? (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '3px', borderRadius: '14px', overflow: 'hidden', border: '1.5px solid #E8E0D8' }}>
            {photos.map((photo, idx) => (
              <motion.div key={photo.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: idx * 0.04 }}
                whileTap={{ opacity: 0.8 }} onClick={() => navigate(`/post/${photo.id}`)}
                style={{ position: 'relative', aspectRatio: '1', cursor: 'pointer', overflow: 'hidden' }}>
                <img src={photo.img} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                {photo.won && (
                  <div style={{ position: 'absolute', top: '4px', right: '4px', width: '20px', height: '20px', borderRadius: '50%', background: '#F2C3B9', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Trophy size={10} color="white" />
                  </div>
                )}
                <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, padding: '4px 5px', background: 'linear-gradient(to top, rgba(44,58,55,0.6), transparent)', display: 'flex', alignItems: 'center', gap: '2px' }}>
                  <Heart size={8} color="white" fill="white" />
                  <span style={{ color: 'white', fontSize: '9px', fontWeight: 700 }}>{photo.votes}</span>
                </div>
              </motion.div>
            ))}
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            {photos.map((photo, idx) => (
              <motion.div key={photo.id} initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: idx * 0.04 }}
                whileTap={{ scale: 0.99 }} onClick={() => navigate(`/post/${photo.id}`)}
                className="flex items-center gap-3"
                style={{ padding: '10px', borderRadius: '14px', background: 'white', border: '1.5px solid #E8E0D8', cursor: 'pointer', boxShadow: '0 1px 6px rgba(44,58,55,0.05)' }}>
                <div style={{ width: '64px', height: '64px', borderRadius: '10px', overflow: 'hidden', flexShrink: 0 }}>
                  <img src={photo.img} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1.5 mb-1 flex-wrap">
                    <div style={{ padding: '2px 8px', borderRadius: '20px', background: 'rgba(151,179,174,0.1)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <Camera size={10} color="#97B3AE" />
                      <span style={{ color: '#97B3AE', fontSize: '11px', fontWeight: 600 }}>{photo.challenge}</span>
                    </div>
                    {photo.won && (
                      <div style={{ padding: '2px 7px', borderRadius: '20px', background: '#F2C3B9', display: 'flex', alignItems: 'center', gap: '3px' }}>
                        <Trophy size={9} color="white" />
                        <span style={{ color: 'white', fontSize: '9px', fontWeight: 700 }}>Menang</span>
                      </div>
                    )}
                  </div>
                  <p style={{ color: '#B8C9C7', fontSize: '12px' }}>{photo.date} 2025</p>
                </div>
                <div className="flex flex-col items-end gap-0.5">
                  <div className="flex items-center gap-1">
                    <Heart size={13} color="#E07B65" fill="#E07B65" />
                    <span style={{ color: '#2C3A37', fontSize: '15px', fontWeight: 800 }}>{photo.votes}</span>
                  </div>
                  <span style={{ color: '#C4D0CE', fontSize: '10px' }}>votes</span>
                </div>
              </motion.div>
            ))}
          </div>
        )}

        {photos.length === 0 && (
          <div className="flex flex-col items-center justify-center py-20 gap-3">
            <div style={{ width: '64px', height: '64px', borderRadius: '20px', background: '#F0EEEA', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Camera size={28} color="#D6CBBF" />
            </div>
            <p style={{ color: '#2C3A37', fontSize: '15px', fontWeight: 700 }}>Belum Ada Foto</p>
            <p style={{ color: '#B8C9C7', fontSize: '13px' }}>Tidak ada foto di bulan ini</p>
          </div>
        )}
      </div>
    </div>
  );
}
