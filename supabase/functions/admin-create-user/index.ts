// Admin xodim hisobini yaratadi yoki o'chiradi.
// Deploy: supabase functions deploy admin-create-user
// SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY Supabase tomonidan avtomatik beriladi
// (service-role kalitini hech qachon ilovaga qo'ymang).
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const STAFF = ["restaurant", "shop", "master", "courier"];

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const authHeader = req.headers.get("Authorization") ?? "";

    // 1) Chaqiruvchi admin ekanini tekshirish
    const caller = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: u } = await caller.auth.getUser();
    if (!u?.user) return json({ error: "Kirish talab qilinadi" }, 401);

    const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const { data: me } = await admin
      .from("profiles").select("role").eq("id", u.user.id).maybeSingle();
    if (me?.role !== "admin") return json({ error: "Faqat admin uchun" }, 403);

    const b = await req.json();

    if (b.action === "create") {
      const email = String(b.email ?? "").trim().toLowerCase();
      const password = String(b.password ?? "");
      const role = b.role;
      if (!STAFF.includes(role)) return json({ error: "Rol noto'g'ri" }, 400);
      const hasStore = role === "restaurant" || role === "shop";
      if (!email.includes("@")) return json({ error: "Email noto'g'ri" }, 400);
      if (password.length < 8) return json({ error: "Parol kamida 8 belgi" }, 400);
      if (hasStore && !String(b.restaurant_name ?? "").trim())
        return json({ error: "Do'kon nomi kerak" }, 400);
      if (role === "master" && !String(b.full_name ?? "").trim())
        return json({ error: "Ustaning ismi kerak" }, 400);

      const { data, error } = await admin.auth.admin.createUser({
        email, password, email_confirm: true,
        user_metadata: { full_name: b.full_name ?? null },
      });
      if (error || !data.user) return json({ error: error?.message ?? "Yaratib bo'lmadi" }, 400);
      const id = data.user.id;

      const { error: pe } = await admin.from("profiles").upsert({
        id, role, email, full_name: b.full_name ?? null, phone: b.phone ?? null,
      });
      if (pe) {
        await admin.auth.admin.deleteUser(id);
        return json({ error: pe.message }, 400);
      }

      // Yangi do'kon va usta profili tasdiqlanguncha ('pending') mijozga ko'rinmaydi.
      let re: { message: string } | null = null;
      if (hasStore) {
        ({ error: re } = await admin.from("restaurants").insert({
          name: String(b.restaurant_name).trim(),
          owner_id: id, owner_email: email, is_active: false,
          ...(role === "shop" ? { kind: "shop" } : {}),
        }));
      } else if (role === "master") {
        ({ error: re } = await admin.from("masters").insert({
          user_id: id, full_name: String(b.full_name).trim(), phone: b.phone ?? null,
        }));
      }
      if (re) {
        await admin.auth.admin.deleteUser(id);
        return json({ error: re.message }, 400);
      }
      return json({ ok: true, user_id: id });
    }

    if (b.action === "remove") {
      const id = String(b.user_id ?? "");
      if (!id || id === u.user.id) return json({ error: "Bu hisobni o'chirib bo'lmaydi" }, 400);
      const { data: t } = await admin.from("profiles").select("role").eq("id", id).maybeSingle();
      if (!t || !STAFF.includes(t.role))
        return json({ error: "Faqat xodim hisobini chiqarish mumkin" }, 400);

      // Do'kon va usta profili yashiriladi (buyurtma tarixi saqlansin)
      await admin.from("restaurants").update({ is_active: false }).eq("owner_id", id);
      if (t.role === "master") {
        await admin.from("masters").update({ is_active: false }).eq("user_id", id);
      }

      const { error } = await admin.auth.admin.deleteUser(id);
      if (error) {
        // Bog'liq buyurtmalar bo'lsa: kirishni bloklaymiz
        const { error: be } = await admin.auth.admin.updateUserById(id, { ban_duration: "876000h" });
        if (be) return json({ error: be.message }, 400);
      }
      await admin.from("profiles").update({ role: "customer" }).eq("id", id);
      return json({ ok: true, mode: error ? "banned" : "deleted" });
    }

    return json({ error: "Noma'lum amal" }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
