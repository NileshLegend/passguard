import { useState, useEffect } from 'react'
import axios from 'axios'
import { useNavigate } from 'react-router-dom'

function checkStrength(password) {
  let score = 0
  if (password.length >= 8) score++
  if (password.length >= 12) score++
  if (/[A-Z]/.test(password) && /[a-z]/.test(password)) score++
  if (/\d/.test(password)) score++
  if (/[^A-Za-z0-9]/.test(password)) score++
  return Math.min(score, 4)
}

function getCrackTime(score) {
  const times = ['instant', 'a few minutes', 'a few hours', 'months', 'millions of years']
  return times[score]
}

const labels = ['Very Weak', 'Weak', 'Fair', 'Strong', 'Very Strong']
const colors = ['#e94560', '#ff9e00', '#ffbe0b', '#3a86ff', '#38b000']
const API = 'https://passguard-production-2c0c.up.railway.app'

export default function Dashboard({ token, setToken }) {
  const [password, setPassword] = useState('')
  const [vault, setVault] = useState([])
  const [siteName, setSiteName] = useState('')
  const [username, setUsername] = useState('')
  const [vaultPassword, setVaultPassword] = useState('')
  const [showPasswords, setShowPasswords] = useState({})
  const [activeTab, setActiveTab] = useState('checker')
  const navigate = useNavigate()
  const score = checkStrength(password)

  const headers = { Authorization: `Bearer ${token}` }

  useEffect(() => {
    axios.get(`${API}/vault`, { headers }).then(res => setVault(res.data))
  }, [])

  const handleSaveVault = async () => {
    if (!siteName || !username || !vaultPassword) return
    await axios.post(`${API}/vault`,
      { site_name: siteName, username, password: vaultPassword },
      { headers }
    )
    const res = await axios.get(`${API}/vault`, { headers })
    setVault(res.data)
    setSiteName('')
    setUsername('')
    setVaultPassword('')
  }

  const handleDelete = async (id) => {
    await axios.delete(`${API}/vault/${id}`, { headers })
    setVault(vault.filter(v => v.id !== id))
  }

  const toggleShow = (id) => {
    setShowPasswords(prev => ({ ...prev, [id]: !prev[id] }))
  }

  const handleLogout = () => {
    localStorage.removeItem('token')
    setToken(null)
    navigate('/login')
  }

  const tabStyle = (tab) => ({
    padding: '0.6rem 1.5rem',
    background: activeTab === tab ? '#28a745' : 'rgba(255,255,255,0.05)',
    border: 'none',
    borderRadius: '8px',
    color: 'white',
    cursor: 'pointer',
    fontWeight: activeTab === tab ? '600' : '400',
    width: 'auto'
  })

  return (
    <div style={{ maxWidth: '650px', margin: '0 auto', padding: '2rem 1rem' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <h1 style={{ fontSize: '1.8rem' }}>🔥 PassGuard</h1>
        <button onClick={handleLogout} style={{ width: 'auto', padding: '0.5rem 1rem', background: 'transparent', border: '1px solid #e94560' }}>Logout</button>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1.5rem' }}>
        <button style={tabStyle('checker')} onClick={() => setActiveTab('checker')}>🔍 Checker</button>
        <button style={tabStyle('vault')} onClick={() => setActiveTab('vault')}>🔐 Vault</button>
      </div>

      {/* Checker Tab */}
      {activeTab === 'checker' && (
        <div className="card">
          <h3 style={{ marginBottom: '1rem' }}>Check Password Strength</h3>
          <input placeholder="Enter password to check..." value={password} onChange={e => setPassword(e.target.value)} />
          {password && <>
            <div style={{ height: '8px', background: 'rgba(255,255,255,0.1)', borderRadius: '4px', marginBottom: '0.5rem' }}>
              <div style={{ height: '100%', width: `${(score / 4) * 100}%`, background: colors[score], borderRadius: '4px', transition: 'all 0.3s' }} />
            </div>
            <p style={{ color: colors[score], marginBottom: '1rem', fontWeight: '600' }}>
              {labels[score]} — cracks in {getCrackTime(score)}
            </p>
          </>}
          <button onClick={() => setPassword('')} style={{ background: 'rgba(255,255,255,0.1)' }}>Clear</button>
        </div>
      )}

      {/* Vault Tab */}
      {activeTab === 'vault' && (
        <div>
          <div className="card" style={{ marginBottom: '1.5rem' }}>
            <h3 style={{ marginBottom: '1rem' }}>➕ Save New Password</h3>
            <input placeholder="Site name (e.g. Facebook)" value={siteName} onChange={e => setSiteName(e.target.value)} />
            <input placeholder="Username or Email" value={username} onChange={e => setUsername(e.target.value)} />
            <input placeholder="Password" type="password" value={vaultPassword} onChange={e => setVaultPassword(e.target.value)} />
            <button onClick={handleSaveVault}>Save Password</button>
          </div>

          <div className="card">
            <h3 style={{ marginBottom: '1rem' }}>🔐 Saved Passwords</h3>
            {vault.length === 0 && <p style={{ opacity: 0.6 }}>No passwords saved yet.</p>}
            {vault.map(item => (
              <div key={item.id} style={{ padding: '1rem 0', borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.4rem' }}>
                  <span style={{ fontWeight: '600', color: '#e94560' }}>🌐 {item.site_name}</span>
                  <button onClick={() => handleDelete(item.id)} style={{ width: 'auto', padding: '0.3rem 0.8rem', background: 'transparent', border: '1px solid #e94560', fontSize: '0.8rem' }}>Delete</button>
                </div>
                <p style={{ opacity: 0.7, fontSize: '0.9rem', marginBottom: '0.3rem' }}>👤 {item.username}</p>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <p style={{ opacity: 0.7, fontSize: '0.9rem', fontFamily: 'monospace' }}>
                    🔑 {showPasswords[item.id] ? item.password : '••••••••'}
                  </p>
                  <button onClick={() => toggleShow(item.id)} style={{ width: 'auto', padding: '0.2rem 0.6rem', background: 'rgba(255,255,255,0.1)', border: 'none', fontSize: '0.75rem' }}>
                    {showPasswords[item.id] ? 'Hide' : 'Show'}
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}