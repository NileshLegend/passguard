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

export default function Dashboard({ token, setToken }) {
  const [password, setPassword] = useState('')
  const [history, setHistory] = useState([])
  const navigate = useNavigate()
  const score = checkStrength(password)

  useEffect(() => {
    axios.get('http://localhost:5000/checks', {
      headers: { Authorization: `Bearer ${token}` }
    }).then(res => setHistory(res.data))
  }, [])

  const handleCheck = async () => {
    if (!password) return
    await axios.post('http://localhost:5000/checks',
      { score, crack_time: getCrackTime(score) },
      { headers: { Authorization: `Bearer ${token}` } }
    )
    const res = await axios.get('http://localhost:5000/checks', {
      headers: { Authorization: `Bearer ${token}` }
    })
    setHistory(res.data)
    setPassword('')
  }

  const handleLogout = () => {
    localStorage.removeItem('token')
    setToken(null)
    navigate('/login')
  }

  return (
    <div style={{ maxWidth: '600px', margin: '0 auto', padding: '2rem 1rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <h1 style={{ fontSize: '1.8rem' }}>🔥 PassGuard</h1>
        <button onClick={handleLogout} style={{ width: 'auto', padding: '0.5rem 1rem', background: 'transparent', border: '1px solid #e94560' }}>Logout</button>
      </div>

      <div className="card" style={{ marginBottom: '1.5rem' }}>
        <h3 style={{ marginBottom: '1rem' }}>Check Your Password</h3>
        <input placeholder="Enter password to check..." value={password} onChange={e => setPassword(e.target.value)} />

        {password && <>
          <div style={{ height: '8px', background: 'rgba(255,255,255,0.1)', borderRadius: '4px', marginBottom: '0.5rem' }}>
            <div style={{ height: '100%', width: `${(score / 4) * 100}%`, background: colors[score], borderRadius: '4px', transition: 'all 0.3s' }} />
          </div>
          <p style={{ color: colors[score], marginBottom: '1rem', fontWeight: '600' }}>
            {labels[score]} — cracks in {getCrackTime(score)}
          </p>
        </>}

        <button onClick={handleCheck}>Save Result</button>
      </div>

      <div className="card">
        <h3 style={{ marginBottom: '1rem' }}>📋 Recent History</h3>
        {history.length === 0 && <p style={{ opacity: 0.6 }}>No checks yet.</p>}
        {history.map(item => (
          <div key={item.id} style={{ display: 'flex', justifyContent: 'space-between', padding: '0.7rem 0', borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
            <span style={{ color: colors[item.score] }}>{labels[item.score]}</span>
            <span style={{ opacity: 0.6, fontSize: '0.85rem' }}>cracks in {item.crack_time}</span>
            <span style={{ opacity: 0.5, fontSize: '0.8rem' }}>{new Date(item.created_at).toLocaleDateString()}</span>
          </div>
        ))}
      </div>
    </div>
  )
}