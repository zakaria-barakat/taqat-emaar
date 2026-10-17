import { supabase, checkIsAdmin } from './supabase.js';

// Application State
const state = {
  user: null,
  isAdmin: false,
  currentTab: 'overview',
  isLoading: false,
  orders: [],
  payments: [],
  products: [],
  categories: [],
  inventoryMovements: [],
  notifications: [],
};

// UI Helpers
function showToast(message, type = 'info') {
  const root = document.getElementById('toast-root');
  if (!root) return;
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.textContent = message;
  root.appendChild(toast);
  setTimeout(() => {
    toast.remove();
  }, 4000);
}

function openModal({ title, bodyHtml, confirmText = 'تأكيد', confirmClass = 'btn-primary', onConfirm }) {
  const root = document.getElementById('modal-root');
  if (!root) return;

  root.innerHTML = `
    <div class="modal-overlay" id="active-modal">
      <div class="modal-card">
        <div class="modal-header">
          <h3 class="box-title">${title}</h3>
          <button class="btn btn-outline btn-sm" id="modal-close-btn">&times;</button>
        </div>
        <div class="modal-body">
          ${bodyHtml}
        </div>
        <div class="modal-footer">
          <button class="btn btn-outline" id="modal-cancel-btn">إلغاء</button>
          <button class="btn ${confirmClass}" id="modal-confirm-btn">${confirmText}</button>
        </div>
      </div>
    </div>
  `;

  const modal = document.getElementById('active-modal');
  const close = () => { root.innerHTML = ''; };

  document.getElementById('modal-close-btn')?.addEventListener('click', close);
  document.getElementById('modal-cancel-btn')?.addEventListener('click', close);
  modal.addEventListener('click', (e) => {
    if (e.target === modal) close();
  });

  document.getElementById('modal-confirm-btn')?.addEventListener('click', async () => {
    if (onConfirm) {
      const btn = document.getElementById('modal-confirm-btn');
      btn.disabled = true;
      btn.textContent = 'جاري التنفيذ...';
      try {
        await onConfirm();
        close();
      } catch (err) {
        showToast(err.message || 'حدث خطأ أثناء التنفيذ', 'error');
        btn.disabled = false;
        btn.textContent = confirmText;
      }
    } else {
      close();
    }
  });
}

// Data Fetchers
async function fetchAllData() {
  state.isLoading = true;
  render();

  try {
    const [
      ordersRes,
      paymentsRes,
      productsRes,
      categoriesRes,
      inventoryRes,
      notificationsRes
    ] = await Promise.all([
      supabase.from('orders').select('*, order_items(*)').order('created_at', { ascending: false }),
      supabase.from('payments').select('*').order('created_at', { ascending: false }),
      supabase.from('products').select('*, product_images(*)').order('created_at', { ascending: false }),
      supabase.from('categories').select('*').order('sort_order', { ascending: true }),
      supabase.from('inventory_movements').select('*, products(name)').order('created_at', { ascending: false }),
      supabase.from('notifications').select('*').order('created_at', { ascending: false })
    ]);

    state.orders = ordersRes.data || [];
    state.payments = paymentsRes.data || [];
    state.products = productsRes.data || [];
    state.categories = categoriesRes.data || [];
    state.inventoryMovements = inventoryRes.data || [];
    state.notifications = notificationsRes.data || [];
  } catch (err) {
    showToast('فشل تحديث البيانات: ' + err.message, 'error');
  } finally {
    state.isLoading = false;
    render();
  }
}

// Actions
async function approvePayment(paymentId, orderTotal) {
  openModal({
    title: 'اعتماد الدفع وخصم المخزون',
    bodyHtml: `
      <p style="margin-bottom: 12px; color: var(--text-muted); font-size: 13.5px;">
        سيتم التحقق من مطابقة المبلغ واعتماد الطلب وخصم كميات المخزون وتسجيل حركة المخزون آليًا.
      </p>
      <div class="form-group">
        <label class="form-label">المبلغ المستلم الفعلي</label>
        <input type="number" step="any" id="received-amount-input" class="form-control" value="${orderTotal}">
      </div>
    `,
    confirmText: 'اعتماد الدفع',
    confirmClass: 'btn-success',
    onConfirm: async () => {
      const amount = parseFloat(document.getElementById('received-amount-input').value);
      if (!amount || amount <= 0) throw new Error('يرجى إدخال مبلغ صحيح أكبر من الصفر');

      const { error } = await supabase.rpc('approve_order_payment', {
        p_payment_id: paymentId,
        p_received_amount: amount,
      });

      if (error) throw error;
      showToast('تم اعتماد الدفع وتحديث المخزون بنجاح!', 'success');
      await fetchAllData();
    }
  });
}

async function rejectPayment(paymentId) {
  openModal({
    title: 'رفض إيصال الدفع',
    bodyHtml: `
      <p style="margin-bottom: 12px; color: var(--text-muted); font-size: 13.5px;">
        يرجى تحديد سبب الرفض المعتمد لإلغاء الطلب وإشعار السجلات.
      </p>
      <div class="form-group">
        <label class="form-label">سبب الرفض</label>
        <select id="rejection-reason-select" class="form-control">
          <option value="no_money_received">لم يتم استلام أي حوالة مالية (no_money_received)</option>
          <option value="insufficient_amount">المبلغ المحول غير كافٍ أو ناقص (insufficient_amount)</option>
        </select>
      </div>
    `,
    confirmText: 'تأكيد الرفض',
    confirmClass: 'btn-danger',
    onConfirm: async () => {
      const reason = document.getElementById('rejection-reason-select').value;
      const { error } = await supabase.rpc('reject_order_payment', {
        p_payment_id: paymentId,
        p_rejection_reason: reason,
      });

      if (error) throw error;
      showToast('تم رفض الدفع وإلغاء الطلب.', 'info');
      await fetchAllData();
    }
  });
}

async function viewReceipt(receiptPath) {
  if (!receiptPath) {
    showToast('لا يوجد مسار إيصال محفوظ لهذا الدفع', 'error');
    return;
  }

  try {
    const { data, error } = await supabase.storage
      .from('payment-receipts')
      .createSignedUrl(receiptPath, 360);

    if (error) throw error;

    openModal({
      title: 'معاينة إيصال التحويل',
      bodyHtml: `
        <div style="text-align: center; max-height: 70vh; overflow: auto;">
          <img src="${data.signedUrl}" alt="إيصال الدفع" style="max-width: 100%; border-radius: 12px; box-shadow: 0 4px 14px rgba(0,0,0,0.1);">
          <div style="margin-top: 12px;">
            <a href="${data.signedUrl}" target="_blank" download class="btn btn-outline btn-sm">تحميل الصورة بدقة كاملة</a>
          </div>
        </div>
      `,
      confirmText: 'إغلاق',
      confirmClass: 'btn-outline',
    });
  } catch (err) {
    showToast('تعذر عرض الإيصال: ' + err.message, 'error');
  }
}

async function updateDeliveryStatus(orderId, newStatus) {
  const statusNames = {
    out_for_delivery: 'بدء التوصيل (قيد التوصيل)',
    delivered: 'تم التسليم بنجاح',
    failed_delivery: 'تعذر التسليم / فشل التوصيل',
  };

  openModal({
    title: 'تحديث حالة التوصيل',
    bodyHtml: `
      <p style="font-size: 14px; line-height: 1.6;">
        هل أنت متأكد من تغيير حالة توصيل الطلب إلى: <strong>${statusNames[newStatus] || newStatus}</strong>؟
      </p>
    `,
    confirmText: 'تأكيد التحديث',
    confirmClass: 'btn-primary',
    onConfirm: async () => {
      const { error } = await supabase.rpc('update_order_delivery_status', {
        p_order_id: orderId,
        p_new_status: newStatus,
      });

      if (error) throw error;
      showToast('تم تحديث حالة التوصيل بنجاح!', 'success');
      await fetchAllData();
    }
  });
}

async function adjustStock(productId, currentStock, productName) {
  openModal({
    title: `تعديل مخزون — ${productName}`,
    bodyHtml: `
      <div class="form-group">
        <label class="form-label">المخزون الحالي: ${currentStock}</label>
      </div>
      <div class="form-group">
        <label class="form-label">الكمية الجديدة بالمخزن</label>
        <input type="number" id="new-stock-input" class="form-control" value="${currentStock}" min="0">
      </div>
      <div class="form-group">
        <label class="form-label">سبب التعديل</label>
        <input type="text" id="stock-reason-input" class="form-control" placeholder="توريد جديد، جرد، تسوية...">
      </div>
    `,
    confirmText: 'حفظ الكمية',
    confirmClass: 'btn-primary',
    onConfirm: async () => {
      const newQty = parseInt(document.getElementById('new-stock-input').value, 10);
      const reason = document.getElementById('stock-reason-input').value.trim() || 'admin_manual_adjustment';

      if (isNaN(newQty) || newQty < 0) throw new Error('يرجى إدخال كمية صحيحة');

      const { error } = await supabase.rpc('admin_adjust_product_stock', {
        p_product_id: productId,
        p_new_quantity: newQty,
        p_reason: reason,
      });

      if (error) throw error;
      showToast('تم تعديل المخزون بنجاح!', 'success');
      await fetchAllData();
    }
  });
}

async function createProductModal() {
  const categoryOptions = state.categories.map(c => `<option value="${c.id}">${c.name}</option>`).join('');

  openModal({
    title: 'إضافة منتج جديد للمتجر',
    bodyHtml: `
      <div class="form-group">
        <label class="form-label">اسم المنتج</label>
        <input type="text" id="p-name" class="form-control" placeholder="أسمنت، حديد تسليح، بلوك...">
      </div>
      <div class="form-group">
        <label class="form-label">التصنيف</label>
        <select id="p-category" class="form-control">
          ${categoryOptions}
        </select>
      </div>
      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
        <div class="form-group">
          <label class="form-label">السعر</label>
          <input type="number" step="any" id="p-price" class="form-control" placeholder="0">
        </div>
        <div class="form-group">
          <label class="form-label">العملة</label>
          <select id="p-currency" class="form-control">
            <option value="YER">ريال يمني (YER)</option>
            <option value="SAR">ريال سعودي (SAR)</option>
            <option value="USD">دولار أمريكي (USD)</option>
          </select>
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">وحدة البيع</label>
        <input type="text" id="p-unit" class="form-control" placeholder="كيس، طن، حبة، متر...">
      </div>
      <div class="form-group">
        <label class="form-label">الوصف والمواصفات</label>
        <textarea id="p-desc" class="form-control" rows="3" placeholder="مواصفات المادة ومصدرها ومعاييرها..."></textarea>
      </div>
      <p style="font-size: 12px; color: var(--text-muted);">ملاحظة: يبدأ المنتج بمخزون 0 وفق القواعد، ويمكنك تعديل كميته فور إضافته.</p>
    `,
    confirmText: 'إضافة المنتج',
    confirmClass: 'btn-gold',
    onConfirm: async () => {
      const name = document.getElementById('p-name').value.trim();
      const categoryId = document.getElementById('p-category').value;
      const price = parseFloat(document.getElementById('p-price').value);
      const currency = document.getElementById('p-currency').value;
      const unit = document.getElementById('p-unit').value.trim();
      const desc = document.getElementById('p-desc').value.trim();

      if (!name) throw new Error('يرجى إدخال اسم المنتج');
      if (isNaN(price) || price < 0) throw new Error('يرجى إدخال سعر صحيح');

      const { data, error } = await supabase.rpc('admin_create_product', {
        p_name: name,
        p_description: desc,
        p_price: price,
        p_currency: currency,
        p_category_id: categoryId,
        p_selling_unit: unit || 'حبة',
      });

      if (error) throw error;
      showToast('تمت إضافة المنتج بنجاح!', 'success');
      await fetchAllData();
    }
  });
}

async function toggleProductActive(productId, currentActive) {
  const { error } = await supabase.rpc('admin_set_product_active', {
    p_product_id: productId,
    p_is_active: !currentActive,
  });

  if (error) {
    showToast('تعذر تغيير الحالة: ' + error.message, 'error');
  } else {
    showToast('تم تحديث حالة المنتج بنجاح!', 'success');
    await fetchAllData();
  }
}

// Render Functions
function renderLogin() {
  const app = document.getElementById('app');
  app.innerHTML = `
    <div class="login-wrap">
      <div class="login-card">
        <div class="brand-header">
          <div class="brand-logo">&#127970;</div>
          <h1 class="brand-title">طاقة إعمار</h1>
          <p class="brand-subtitle">لوحة الإدارة والتحكم الموحدة | Taqat Emaar</p>
        </div>

        <form id="login-form">
          <div class="form-group">
            <label class="form-label">البريد الإلكتروني للإدارة</label>
            <input type="email" id="email" class="form-control" required placeholder="admin@taqat-emaar.ye">
          </div>

          <div class="form-group">
            <label class="form-label">كلمة المرور</label>
            <input type="password" id="password" class="form-control" required placeholder="••••••••">
          </div>

          <button type="submit" class="btn btn-primary" style="width: 100%; margin-top: 10px;" id="login-btn">
            تسجيل الدخول إلى لوحة الإدارة
          </button>
        </form>
      </div>
    </div>
  `;

  document.getElementById('login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('login-btn');
    btn.disabled = true;
    btn.textContent = 'جاري التحقق...';

    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;

    const { data, error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) {
      showToast('فشل تسجيل الدخول: ' + error.message, 'error');
      btn.disabled = false;
      btn.textContent = 'تسجيل الدخول إلى لوحة الإدارة';
      return;
    }

    state.user = data.user;
    const isAdmin = await checkIsAdmin();

    if (!isAdmin) {
      await supabase.auth.signOut();
      state.user = null;
      showToast('عذرًا، هذا الحساب ليس لديه صلاحية مسؤول في طاقة إعمار.', 'error');
      btn.disabled = false;
      btn.textContent = 'تسجيل الدخول إلى لوحة الإدارة';
      return;
    }

    state.isAdmin = true;
    showToast('مرحبًا بك في لوحة تحكم طاقة إعمار!', 'success');
    await fetchAllData();
  });
}

function renderOverview() {
  const pendingPayments = state.payments.filter(p => p.status === 'pending');
  const deliveredOrders = state.orders.filter(o => o.status === 'delivered');
  const totalStock = state.products.reduce((sum, p) => sum + (p.stock_quantity || 0), 0);

  return `
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon" style="background: rgba(240, 173, 53, 0.15); color: var(--navy);">&#128230;</div>
        <div>
          <div class="stat-val">${state.orders.length}</div>
          <div class="stat-lbl">إجمالي الطلبات</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: var(--warning-bg); color: var(--warning);">&#128179;</div>
        <div>
          <div class="stat-val">${pendingPayments.length}</div>
          <div class="stat-lbl">إيصالات بانتظار الاعتماد</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: var(--success-bg); color: var(--success);">&#9989;</div>
        <div>
          <div class="stat-val">${deliveredOrders.length}</div>
          <div class="stat-lbl">طلبات تم تسليمها</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #EFF8FF; color: #175CD3;">&#128202;</div>
        <div>
          <div class="stat-val">${totalStock}</div>
          <div class="stat-lbl">إجمالي المخزون المتاح</div>
        </div>
      </div>
    </div>

    <div class="content-box">
      <div class="box-header">
        <h3 class="box-title">&#128179; المدفوعات المعلقة للمراجعة والاعتماد</h3>
        <button class="btn btn-outline btn-sm" onclick="window.switchTab('payments')">عرض جميع المدفوعات</button>
      </div>
      ${renderPaymentsTable(pendingPayments.slice(0, 5))}
    </div>

    <div class="content-box">
      <div class="box-header">
        <h3 class="box-title">&#128666; أحدث طلبات المتجر</h3>
        <button class="btn btn-outline btn-sm" onclick="window.switchTab('orders')">عرض جميع الطلبات</button>
      </div>
      ${renderOrdersTable(state.orders.slice(0, 5))}
    </div>
  `;
}

function renderPaymentsTable(paymentsList) {
  if (paymentsList.length === 0) {
    return `<p style="padding: 24px; text-align: center; color: var(--text-muted);">لا توجد إيصالات مدفوعات معلقة حاليًا.</p>`;
  }

  return `
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>معرّف الطلب</th>
            <th>المبلغ المطلوب</th>
            <th>طريقة الدفع</th>
            <th>الرقم المرجعي</th>
            <th>حالة التحقق</th>
            <th>تاريخ الرفع</th>
            <th>الإجراءات</th>
          </tr>
        </thead>
        <tbody>
          ${paymentsList.map(p => {
            const badgeClass = p.status === 'verified' ? 'badge-success' : p.status === 'rejected' ? 'badge-danger' : 'badge-pending';
            const statusText = p.status === 'verified' ? 'معتمد' : p.status === 'rejected' ? 'مرفوض' : 'قيد المراجعة';
            const order = state.orders.find(o => o.id === p.order_id);
            const total = order ? order.total_amount : p.amount;

            return `
              <tr>
                <td><strong>#${p.order_id.substring(0, 8)}</strong></td>
                <td><strong style="color: var(--navy); font-size: 15px;">${p.amount} ${p.currency}</strong></td>
                <td>${p.payment_method}</td>
                <td>${p.reference_number || '<span style="color: #999;">غير محدد</span>'}</td>
                <td><span class="badge ${badgeClass}">${statusText}</span></td>
                <td>${new Date(p.created_at).toLocaleString('ar-YE')}</td>
                <td>
                  <div style="display: flex; gap: 6px;">
                    ${p.receipt_url ? `<button class="btn btn-outline btn-sm" onclick="window.viewReceipt('${p.receipt_url}')">&#128065; الإيصال</button>` : ''}
                    ${p.status === 'pending' ? `
                      <button class="btn btn-success btn-sm" onclick="window.approvePayment('${p.id}', ${total})">&#10004; اعتماد</button>
                      <button class="btn btn-danger btn-sm" onclick="window.rejectPayment('${p.id}')">&#10006; رفض</button>
                    ` : ''}
                  </div>
                </td>
              </tr>
            `;
          }).join('')}
        </tbody>
      </table>
    </div>
  `;
}

function renderOrdersTable(ordersList) {
  if (ordersList.length === 0) {
    return `<p style="padding: 24px; text-align: center; color: var(--text-muted);">لا توجد طلبات معروضة.</p>`;
  }

  return `
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>رقم الطلب</th>
            <th>الهاتف والعنوان</th>
            <th>الأصناف المطلوبة</th>
            <th>الإجمالي</th>
            <th>حالة الدفع</th>
            <th>حالة التوصيل</th>
            <th>تأكيد استلام العميل</th>
            <th>إجراءات التوصيل</th>
          </tr>
        </thead>
        <tbody>
          ${ordersList.map(o => {
            const isConfirmed = Boolean(o.received_confirmed_at);
            const pBadge = o.payment_status === 'verified' ? 'badge-success' : o.payment_status === 'rejected' ? 'badge-danger' : 'badge-pending';
            const pText = o.payment_status === 'verified' ? 'مدفوع ومعتمد' : o.payment_status === 'rejected' ? 'دفع مرفوض' : 'في انتظار الدفع';

            const statusBadges = {
              pending: '<span class="badge badge-pending">قيد الانتظار</span>',
              preparing: '<span class="badge badge-info">جاري التجهيز بالمستودع</span>',
              out_for_delivery: '<span class="badge badge-warning">قيد التوصيل بالسيارة</span>',
              delivered: '<span class="badge badge-success">تم التوصيل</span>',
              cancelled: '<span class="badge badge-danger">ملغي</span>',
              failed_delivery: '<span class="badge badge-danger">فشل التسليم</span>',
            };

            const itemsSummary = (o.order_items || [])
              .map(i => `${i.product_name} (${i.quantity})`)
              .join(', ') || 'تفاصيل الأصناف';

            return `
              <tr>
                <td><strong>#${o.id.substring(0, 8)}</strong></td>
                <td>
                  <div style="font-weight: 700;">${o.customer_phone}</div>
                  <div style="font-size: 12px; color: var(--text-muted);">${o.delivery_address}</div>
                </td>
                <td style="max-width: 200px; font-size: 12.5px;">${itemsSummary}</td>
                <td><strong style="color: var(--navy); font-size: 15px;">${o.total_amount} ${o.currency}</strong></td>
                <td><span class="badge ${pBadge}">${pText}</span></td>
                <td>${statusBadges[o.status] || o.status}</td>
                <td>
                  ${isConfirmed 
                    ? `<span class="badge badge-success">&#9989; أكد الاستلام (${new Date(o.received_confirmed_at).toLocaleDateString('ar-YE')})</span>` 
                    : `<span class="badge badge-outline" style="color: #888;">لم يؤكد بعد</span>`
                  }
                </td>
                <td>
                  <div style="display: flex; gap: 4px; flex-wrap: wrap;">
                    ${o.status === 'preparing' ? `
                      <button class="btn btn-primary btn-sm" onclick="window.updateDeliveryStatus('${o.id}', 'out_for_delivery')">&#128666; بدء التوصيل</button>
                    ` : ''}
                    ${o.status === 'out_for_delivery' ? `
                      <button class="btn btn-success btn-sm" onclick="window.updateDeliveryStatus('${o.id}', 'delivered')">&#10004; تم التسليم</button>
                      <button class="btn btn-danger btn-sm" onclick="window.updateDeliveryStatus('${o.id}', 'failed_delivery')">&#9888; تعذر التسليم</button>
                    ` : ''}
                    ${o.status === 'failed_delivery' ? `
                      <button class="btn btn-warning btn-sm" onclick="window.updateDeliveryStatus('${o.id}', 'out_for_delivery')">&#8635; إعادة محاولة</button>
                    ` : ''}
                  </div>
                </td>
              </tr>
            `;
          }).join('')}
        </tbody>
      </table>
    </div>
  `;
}

function renderProductsView() {
  return `
    <div class="content-box">
      <div class="box-header">
        <div>
          <h3 class="box-title">&#128230; مواد البناء والمنتجات</h3>
          <p style="font-size: 12.5px; color: var(--text-muted); margin-top: 2px;">إدارة المواد، تعديل الأسعار، وضبط كميات المستودع</p>
        </div>
        <button class="btn btn-gold" onclick="window.createProductModal()">+ إضافة منتج جديد</button>
      </div>

      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>المنتج</th>
              <th>التصنيف</th>
              <th>السعر</th>
              <th>الوحدة</th>
              <th>المخزون الحالي</th>
              <th>الحالة</th>
              <th>الإجراءات</th>
            </tr>
          </thead>
          <tbody>
            ${state.products.map(p => {
              const cat = state.categories.find(c => c.id === p.category_id);
              const isLowStock = p.stock_quantity <= 5;

              return `
                <tr>
                  <td>
                    <div style="font-weight: 800; color: var(--navy);">${p.name}</div>
                    <div style="font-size: 12px; color: var(--text-muted);">${p.description || ''}</div>
                  </td>
                  <td>${cat ? cat.name : '—'}</td>
                  <td><strong>${p.price} ${p.currency}</strong></td>
                  <td>لكل ${p.selling_unit}</td>
                  <td>
                    <span style="font-weight: 800; font-size: 15px; color: ${isLowStock ? 'var(--danger)' : 'var(--navy)'};">
                      ${p.stock_quantity}
                    </span>
                    ${isLowStock ? '<span style="font-size: 11px; color: var(--danger); display: block;">مخزون منخفض!</span>' : ''}
                  </td>
                  <td>
                    <button class="btn btn-sm ${p.is_active ? 'btn-outline' : 'btn-danger'}" onclick="window.toggleProductActive('${p.id}', ${p.is_active})">
                      ${p.is_active ? '&#9989; نشط' : '&#10060; معطّل'}
                    </button>
                  </td>
                  <td>
                    <button class="btn btn-primary btn-sm" onclick="window.adjustStock('${p.id}', ${p.stock_quantity}, '${p.name}')">&#9874; ضبط المخزون</button>
                  </td>
                </tr>
              `;
            }).join('')}
          </tbody>
        </table>
      </div>
    </div>
  `;
}

function renderCategoriesView() {
  return `
    <div class="content-box">
      <div class="box-header">
        <div>
          <h3 class="box-title">&#128193; أقسام وتصنيفات المتجر</h3>
          <p style="font-size: 12.5px; color: var(--text-muted); margin-top: 2px;">إدارة أقسام مواد البناء وترتيب ظهورها</p>
        </div>
      </div>

      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>اسم القسم</th>
              <th>القسم الأب</th>
              <th>الترتيب</th>
              <th>الحالة</th>
            </tr>
          </thead>
          <tbody>
            ${state.categories.map(c => {
              const parent = state.categories.find(p => p.id === c.parent_id);
              return `
                <tr>
                  <td><strong>${c.name}</strong></td>
                  <td>${parent ? parent.name : '— (قسم رئيسي)'}</td>
                  <td>${c.sort_order}</td>
                  <td><span class="badge ${c.is_active ? 'badge-success' : 'badge-danger'}">${c.is_active ? 'نشط' : 'معطّل'}</span></td>
                </tr>
              `;
            }).join('')}
          </tbody>
        </table>
      </div>
    </div>
  `;
}

function renderInventoryView() {
  return `
    <div class="content-box">
      <div class="box-header">
        <div>
          <h3 class="box-title">&#128203; سجل حركات المخزون والمستودع</h3>
          <p style="font-size: 12.5px; color: var(--text-muted); margin-top: 2px;">توثيق كافة حركات الخصم والتوريد والتسويات آليًا</p>
        </div>
      </div>

      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>المنتج</th>
              <th>حجم التغيير</th>
              <th>رقم الطلب المرتبط</th>
              <th>السبب والبيان</th>
              <th>التاريخ والوقت</th>
            </tr>
          </thead>
          <tbody>
            ${state.inventoryMovements.map(m => {
              const isDeduction = m.quantity_change < 0;
              return `
                <tr>
                  <td><strong>${m.products ? m.products.name : m.product_id}</strong></td>
                  <td>
                    <span style="font-weight: 800; font-size: 15px; color: ${isDeduction ? 'var(--danger)' : 'var(--success)'};">
                      ${m.quantity_change > 0 ? '+' : ''}${m.quantity_change}
                    </span>
                  </td>
                  <td>${m.order_id ? `#${m.order_id.substring(0, 8)}` : '—'}</td>
                  <td>${m.reason}</td>
                  <td>${new Date(m.created_at).toLocaleString('ar-YE')}</td>
                </tr>
              `;
            }).join('')}
          </tbody>
        </table>
      </div>
    </div>
  `;
}

function renderNotificationsView() {
  return `
    <div class="content-box">
      <div class="box-header">
        <div>
          <h3 class="box-title">&#128276; إشعارات وتنبيهات الإدارة</h3>
          <p style="font-size: 12.5px; color: var(--text-muted); margin-top: 2px;">تشمل تأكيدات استلام العملاء للشحنات والتنبيهات الميدانية</p>
        </div>
      </div>

      <div style="display: flex; flex-direction: column; gap: 12px;">
        ${state.notifications.length === 0 ? '<p style="color: var(--text-muted); text-align: center; padding: 20px;">لا توجد إشعارات مسجلة.</p>' : ''}
        ${state.notifications.map(n => {
          return `
            <div style="background: ${n.is_read ? '#FFFFFF' : 'var(--gold-bg)'}; border: 1px solid var(--border); border-radius: 14px; padding: 16px; display: flex; align-items: center; justify-content: space-between; gap: 14px;">
              <div>
                <div style="font-weight: 800; color: var(--navy); font-size: 15px;">${n.title}</div>
                <div style="color: var(--text-muted); font-size: 13px; margin-top: 4px;">${n.message}</div>
                <div style="font-size: 11px; color: #999; margin-top: 6px;">${new Date(n.created_at).toLocaleString('ar-YE')}</div>
              </div>
              ${n.order_id ? `<button class="btn btn-outline btn-sm" onclick="window.switchTab('orders')">عرض الطلب</button>` : ''}
            </div>
          `;
        }).join('')}
      </div>
    </div>
  `;
}

// App Shell Router
function render() {
  const app = document.getElementById('app');
  if (!state.user || !state.isAdmin) {
    renderLogin();
    return;
  }

  const unreadCount = state.notifications.filter(n => !n.is_read).length;
  const pendingCount = state.payments.filter(p => p.status === 'pending').length;

  app.innerHTML = `
    <div class="app-shell">
      <aside class="sidebar">
        <div class="sidebar-header">
          <div class="logo-mini">&#127970;</div>
          <div>
            <div style="font-weight: 900; font-size: 18px; color: var(--gold);">طاقة إعمار</div>
            <div style="font-size: 11px; opacity: 0.7;">لوحة إدارة المتجر</div>
          </div>
        </div>

        <nav class="sidebar-nav">
          <button class="nav-item ${state.currentTab === 'overview' ? 'active' : ''}" onclick="window.switchTab('overview')">
            &#128200; نظرة عامة
          </button>
          <button class="nav-item ${state.currentTab === 'payments' ? 'active' : ''}" onclick="window.switchTab('payments')">
            &#128179; مراجعة المدفوعات
            ${pendingCount > 0 ? `<span class="nav-badge">${pendingCount}</span>` : ''}
          </button>
          <button class="nav-item ${state.currentTab === 'orders' ? 'active' : ''}" onclick="window.switchTab('orders')">
            &#128666; الطلبات والتوصيل
          </button>
          <button class="nav-item ${state.currentTab === 'products' ? 'active' : ''}" onclick="window.switchTab('products')">
            &#128230; المواد والمنتجات
          </button>
          <button class="nav-item ${state.currentTab === 'categories' ? 'active' : ''}" onclick="window.switchTab('categories')">
            &#128193; أقسام المتجر
          </button>
          <button class="nav-item ${state.currentTab === 'inventory' ? 'active' : ''}" onclick="window.switchTab('inventory')">
            &#128203; حركات المخزون
          </button>
          <button class="nav-item ${state.currentTab === 'notifications' ? 'active' : ''}" onclick="window.switchTab('notifications')">
            &#128276; الإشعارات والتأكيدات
            ${unreadCount > 0 ? `<span class="nav-badge">${unreadCount}</span>` : ''}
          </button>
        </nav>

        <div class="sidebar-footer">
          <div class="user-snippet">
            <div style="overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 140px;">
              <div style="font-weight: 800; font-size: 12px; color: white;">مسؤول النظام</div>
              <div style="font-size: 10.5px; opacity: 0.7; overflow: hidden; text-overflow: ellipsis;">${state.user.email}</div>
            </div>
            <button class="btn btn-outline btn-sm" style="color: white; border-color: rgba(255,255,255,0.2);" onclick="window.logout()">خروج</button>
          </div>
        </div>
      </aside>

      <main class="main-content">
        <header class="top-bar">
          <div>
            <h1 class="page-title">
              ${
                state.currentTab === 'overview' ? 'لوحة القيادة والمؤشرات' :
                state.currentTab === 'payments' ? 'مراجعة المدفوعات والتحويلات البنكية' :
                state.currentTab === 'orders' ? 'إدارة الطلبات ومتابعة التوصيل' :
                state.currentTab === 'products' ? 'إدارة المواد والمنتجات' :
                state.currentTab === 'categories' ? 'إدارة تصنيفات مواد البناء' :
                state.currentTab === 'inventory' ? 'سجل حركات وتوريد المخزون' :
                'الإشعارات وتأكيدات استلام الطلبات'
              }
            </h1>
            <p class="page-desc">نظام متكامل لإدارة منصة طاقة إعمار لمواد البناء</p>
          </div>

          <div style="display: flex; gap: 10px;">
            <button class="btn btn-outline" onclick="window.refreshAll()">
              ${state.isLoading ? 'جاري التحديث...' : '&#8635; تحديث البيانات'}
            </button>
          </div>
        </header>

        ${
          state.currentTab === 'overview' ? renderOverview() :
          state.currentTab === 'payments' ? `<div class="content-box"><div class="box-header"><h3 class="box-title">&#128179; سجل المدفوعات والإيصالات</h3></div>${renderPaymentsTable(state.payments)}</div>` :
          state.currentTab === 'orders' ? `<div class="content-box"><div class="box-header"><h3 class="box-title">&#128666; قائمة الطلبات</h3></div>${renderOrdersTable(state.orders)}</div>` :
          state.currentTab === 'products' ? renderProductsView() :
          state.currentTab === 'categories' ? renderCategoriesView() :
          state.currentTab === 'inventory' ? renderInventoryView() :
          renderNotificationsView()
        }
      </main>
    </div>
  `;
}

// Global window bindings for HTML event handlers
window.switchTab = (tab) => {
  state.currentTab = tab;
  render();
};

window.refreshAll = () => fetchAllData();
window.approvePayment = approvePayment;
window.rejectPayment = rejectPayment;
window.viewReceipt = viewReceipt;
window.updateDeliveryStatus = updateDeliveryStatus;
window.adjustStock = adjustStock;
window.createProductModal = createProductModal;
window.toggleProductActive = toggleProductActive;

window.logout = async () => {
  await supabase.auth.signOut();
  state.user = null;
  state.isAdmin = false;
  render();
};

// Application Bootstrap
async function initApp() {
  const { data: { session } } = await supabase.auth.getSession();
  if (session && session.user) {
    state.user = session.user;
    state.isAdmin = await checkIsAdmin();
    if (state.isAdmin) {
      await fetchAllData();
      return;
    }
  }
  render();
}

initApp();
