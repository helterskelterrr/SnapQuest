import { motion, AnimatePresence } from 'motion/react';
import { CheckCircle2, AlertCircle, Info, X } from 'lucide-react';

export type ToastType = 'success' | 'error' | 'info' | 'warning';

interface ToastProps {
  message: string;
  type: ToastType;
  onDismiss: () => void;
}

const CONFIG = {
  success: { icon: CheckCircle2, bg: '#D2E0D3', border: 'rgba(74,112,107,0.3)', icon_color: '#4A706B', text: '#2C3A37' },
  error:   { icon: AlertCircle,  bg: '#F0DDD6', border: 'rgba(224,123,101,0.3)', icon_color: '#E07B65', text: '#2C3A37' },
  info:    { icon: Info,         bg: '#F0EEEA', border: 'rgba(151,179,174,0.4)', icon_color: '#97B3AE', text: '#2C3A37' },
  warning: { icon: AlertCircle,  bg: '#F2C3B9', border: 'rgba(140,74,54,0.25)', icon_color: '#8C4A36', text: '#2C3A37' },
};

export function Toast({ message, type, onDismiss }: ToastProps) {
  const cfg = CONFIG[type];
  const Icon = cfg.icon;
  return (
    <motion.div
      initial={{ opacity: 0, y: -16, scale: 0.96 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: -10, scale: 0.96 }}
      transition={{ type: 'spring', stiffness: 340, damping: 28 }}
      style={{
        position: 'absolute', top: '12px', left: '16px', right: '16px', zIndex: 999,
        background: cfg.bg, border: `1.5px solid ${cfg.border}`,
        borderRadius: '14px', padding: '12px 14px',
        display: 'flex', alignItems: 'center', gap: '10px',
        boxShadow: '0 8px 32px rgba(44,58,55,0.14)',
      }}
    >
      <Icon size={18} color={cfg.icon_color} strokeWidth={2} style={{ flexShrink: 0 }} />
      <p style={{ color: cfg.text, fontSize: '13px', fontWeight: 600, flex: 1, lineHeight: 1.4 }}>{message}</p>
      <button onClick={onDismiss} style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: '2px', flexShrink: 0 }}>
        <X size={15} color="#9EAEAD" />
      </button>
    </motion.div>
  );
}
