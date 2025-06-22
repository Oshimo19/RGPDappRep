/**
 * JS Dashboard :
 *  - Lit le JWT depuis localStorage
 *  - Appelle /api/user/dashboard avec Authorization: Bearer
 *  - Affiche email, rôle et date d’expiration
 *  - Auto-deconnecte a l’expiration ou sur clic « logout »
 */

document.addEventListener("DOMContentLoaded", () => {
  const token = localStorage.getItem("jwt_token");
  if (!token) {
    alert("Acces interdit : veuillez vous connecter");
    window.location.href = "/login";
    return;
  }

  /* --- Helper pour decoder le payload JWT --- */
  function decodeJwtPayload(jwt) {                       
    const b64 = jwt.split(".")[1];
    const padded = b64.padEnd(b64.length + (4 - b64.length % 4) % 4, "=");
    const json  = atob(padded.replace(/-/g, "+").replace(/_/g, "/"));
    return JSON.parse(json);
  }

  /* --- Affichage pre-charge (exp, puis appel API) --- */
  try {                                                  
    const payload   = decodeJwtPayload(token);
    const expDate   = new Date(payload.exp * 1000);
    const timeLeft  = payload.exp * 1000 - Date.now();

    document.getElementById("tokenExp").textContent =
      "Expire : " + expDate.toLocaleString("fr-FR");

    // Auto-logout quand le token arrive a expiration
    if (timeLeft > 0) {
      setTimeout(() => {
        localStorage.removeItem("jwt_token");
        window.location.href = "/login";
      }, timeLeft + 500); // petite marge
    }
  } catch (e) {
    console.warn("JWT illisible :", e);
  }

  /* --- Appel API securise --- */
  fetch("/api/user/dashboard", {
    headers: { Authorization: `Bearer ${token}` }
  })
    .then(r => {
      if (!r.ok) throw new Error("Token invalide/expire");
      return r.json();
    })
    .then(data => {
      document.getElementById("userEmail").textContent = "Email : " + data.email;
      document.getElementById("userRole").textContent  = "Rôle : "  + data.role;
    })
    .catch(() => {
      alert("Session expiree ou invalide");
      localStorage.removeItem("jwt_token");
      window.location.href = "/login";
    });

  /* --- Logout manuel --- */
  document.getElementById("logoutBtn").addEventListener("click", () => {
    fetch("/api/logout", { method: "POST" }).finally(() => {
      localStorage.removeItem("jwt_token");
      window.location.href = "/login";
    });
  });
});
