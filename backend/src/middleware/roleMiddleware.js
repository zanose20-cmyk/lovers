function requireRole(...requiredRoles) {
  return (req, res, next) => {
    const user = req.user;
    if (!user) return res.status(401).json({ error: 'Unauthorized' });
    const userRoles = Array.isArray(user.roles) ? user.roles : [];
    const ok = requiredRoles.some((r) => userRoles.includes(r) || userRoles.includes('admin'));
    if (ok) return next();
    return res.status(403).json({ error: 'Forbidden' });
  };
}

module.exports = { requireRole };
