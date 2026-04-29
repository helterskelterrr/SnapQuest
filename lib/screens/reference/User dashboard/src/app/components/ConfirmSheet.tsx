import { motion, AnimatePresence } from 'motion/react';
import { AlertTriangle } from 'lucide-react';

interface ConfirmSheetProps {
  open: boolean;
  title: string;
  body: string;
  confirmLabel?: string;
  cancelLabel?: string;
  danger?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export function ConfirmSheet({
  open, title, body, confirmLabel = 'Ya, Lanjutkan', cancelLabel = 'Batal', danger = false,
  onConfirm, onCancel,
}: ConfirmSheetProps) {
  return (
    <AnimatePresence>
      {open && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onCancel}
          style={{ position: 'absolute', inset: 0, background: 'rgba(44,58,55,0.45)', zIndex: 200, display: 'flex', alignItems: 'flex-end' }}
        >
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            onClick={(e) => e.stopPropagation()}
            style={{ width: '100%', background: 'white', borderRadius: '24px 24px 0 0', padding: '24px 20px 32px' }}
          >
            <div style={{ width: '36px', height: '4px', borderRadius: '2px', background: '#D6CBBF', margin: '0 auto 20px' }} />
            <div className="flex items-start gap-3 mb-4">
              <div style={{ width: '44px', height: '44px', borderRadius: '14px', background: danger ? '#F0DDD6' : '#D2E0D3', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <AlertTriangle size={20} color={danger ? '#E07B65' : '#4A706B'} />
              </div>
              <div>
                <h3 style={{ color: '#2C3A37', fontSize: '17px', fontWeight: 800, marginBottom: '4px' }}>{title}</h3>
                <p style={{ color: '#9EAEAD', fontSize: '14px', lineHeight: 1.5 }}>{body}</p>
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button
                onClick={onCancel}
                style={{ flex: 1, height: '52px', borderRadius: '14px', background: '#FAFAF8', border: '1.5px solid #E8E0D8', color: '#627370', fontSize: '15px', fontWeight: 600, cursor: 'pointer' }}
              >
                {cancelLabel}
              </button>
              <button
                onClick={onConfirm}
                style={{ flex: 1, height: '52px', borderRadius: '14px', background: danger ? '#E07B65' : '#97B3AE', border: 'none', color: 'white', fontSize: '15px', fontWeight: 700, cursor: 'pointer', boxShadow: danger ? '0 6px 20px rgba(224,123,101,0.35)' : '0 6px 20px rgba(151,179,174,0.35)' }}
              >
                {confirmLabel}
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
