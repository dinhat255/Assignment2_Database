// src/pages/user/UserList.tsx

import React, { useState, useCallback, useMemo } from 'react';
import MainLayout from '../../components/layout/MainLayout';
import Table, { Column } from '../../components/ui/Table';
import Button from '../../components/ui/Button';
import Input from '../../components/ui/Input';
import Pagination from '../../components/ui/Pagination';
import Modal from '../../components/ui/Modal';
import UserForm from '../../components/forms/UserForm';
import { useFetch } from '../../hooks/useFetch';
import { Search, UserPlus, Trash2, Eye, Loader2 } from 'lucide-react';
import { formatDate } from '../../utils/format';
import { useNavigate } from 'react-router-dom';
import axiosClient from '../../api/axiosClient';

// Interface User (camelCase để khớp với Backend)
interface User {
  userID: string;
  accountName: string;
  accountPassword?: string;
  fullName: string;
  email: string;
  role: string;
  accountState: boolean;
  enrollmentDate: string;
  phoneNumber?: string;
  nation?: string;
  province?: string;
  ward?: string;
}

type UserSortKey = 'userID' | 'fullName' | 'email' | 'enrollmentDate' | 'accountName';

const UserList: React.FC = () => {
  const navigate = useNavigate();
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [userToDelete, setUserToDelete] = useState<User | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [sortKey, setSortKey] = useState<UserSortKey>('fullName');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('asc');
  const [searchTerm, setSearchTerm] = useState('');
  const [refetchKey, setRefetchKey] = useState(0);

  const { data: teachers } = useFetch<any[]>('/Teacher');
  const teacherIds = useMemo(() => {
    return new Set(teachers?.map((t: any) => t.teacherID) || []);
  }, [teachers]);
  // URL Fetch Data
  const fetchUrl = useMemo(() => {
    const beSortKey = (key: UserSortKey) => {
      switch (key) {
        // NOTE: Backend doesn't expose sort by ID, map userID to name for server-side
        case 'userID': return 'name';
        case 'fullName': return 'name';
        case 'email': return 'email';
        case 'enrollmentDate': return 'date';
        case 'accountName': return 'account';
        default: return 'name';
      }
    }

    // If sorting by userID we will sort client-side; still request base data from server
    const serverSort = sortKey === 'userID' ? 'name' : beSortKey(sortKey);
    return `/UserTable?sortBy=${serverSort}&sortOrder=${sortDirection}&refetch=${refetchKey}`;
  }, [sortKey, sortDirection, refetchKey]);

  const { data: fetchedUsers, isLoading, error } = useFetch<User[]>(fetchUrl);

  const { paginatedUsers, totalItems, totalPages } = useMemo(() => {
    let filtered = fetchedUsers || [];

    if (searchTerm) {
      const lowerCaseSearch = searchTerm.toLowerCase();
      filtered = filtered.filter(user =>
        user.fullName.toLowerCase().includes(lowerCaseSearch) ||
        user.email.toLowerCase().includes(lowerCaseSearch) ||
        user.accountName.toLowerCase().includes(lowerCaseSearch)
      );
    }

    // If sorting by userID, perform client-side sort (server doesn't support ID sort)
    if (sortKey === 'userID') {
      filtered = [...filtered].sort((a, b) => {
        const aId = a.userID || '';
        const bId = b.userID || '';
        return sortDirection === 'asc' ? aId.localeCompare(bId) : bId.localeCompare(aId);
      });
    }

    const totalItems = filtered.length;
    const totalPages = Math.ceil(totalItems / itemsPerPage) || 1;
    const start = (currentPage - 1) * itemsPerPage;
    const paginatedUsers = filtered.slice(start, start + itemsPerPage);

    return { paginatedUsers, totalItems, totalPages };
  }, [fetchedUsers, searchTerm, currentPage, itemsPerPage, sortKey, sortDirection]);

  // --- HÀM TẠO MỚI (POST) ---
  const handleCreateUser = useCallback(async (formData: User) => {
    setIsSubmitting(true);
    try {
      await axiosClient.post('/UserTable', {
        ...formData,
        EnrollmentDate: new Date().toISOString().split('T')[0],
        AccountPassword: formData.accountPassword || 'default@123'
      });
      alert(`Tạo mới thành công User: ${formData.fullName}!`);
      setIsModalOpen(false);
      setRefetchKey(prev => prev + 1);
    } catch (err: any) {
      alert(`Lỗi tạo mới: ${err.response?.data?.message || err.message}`);
    } finally {
      setIsSubmitting(false);
    }
  }, []);

  // --- HÀM XÓA (DELETE) ---
  // Hàm này được gọi khi bấm nút "Xác nhận Xóa" trong Modal
  const handleDelete = useCallback(async (user: User) => {
    setIsSubmitting(true);
    try {
      // Log ID để kiểm tra xem có đúng ID không
      console.log("Deleting User ID:", user.userID);

      if (!user.userID) throw new Error("User ID is missing!");

      await axiosClient.delete(`/UserTable/${user.userID}`);

      alert(`Đã xóa thành công User: ${user.fullName}`);
      setUserToDelete(null); // Đóng modal
      setRefetchKey(prev => prev + 1); // Refresh list
    } catch (err: any) {
      console.error("Delete Error:", err);
      alert(`Lỗi xóa: ${err.response?.data?.message || err.message}`);
    } finally {
      setIsSubmitting(false);
    }
  }, []);

  const handleTableSort = useCallback((key: keyof User) => {
    if (['userID', 'fullName', 'email', 'enrollmentDate', 'accountName'].includes(key as string)) {
      if (sortKey === key) {
        setSortDirection(prev => prev === 'asc' ? 'desc' : 'asc');
      } else {
        setSortKey(key as UserSortKey);
        setSortDirection('asc');
      }
    }
  }, [sortKey]);

  // --- CẤU HÌNH CỘT VÀ NÚT BẤM ---
  const userColumns: Column<User>[] = [
    { key: 'userID', header: 'ID', sortable: true },
    { key: 'accountName', header: 'Tên TK', sortable: true },
    { key: 'fullName', header: 'Họ Tên', sortable: true },
    { key: 'email', header: 'Email', sortable: true },
    {
      key: 'role', header: 'Vai trò', sortable: false,
      render: (user) => {
        // Logic 1: Nếu là tài khoản sManager -> Admin
        if (user.accountName === 'sManager') {
          return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">Admin</span>;
        }
        // Logic 2: Nếu ID có trong danh sách Teacher -> Teacher
        if (teacherIds.has(user.userID)) {
          return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">Giảng viên</span>;
        }
        // Logic 3: Còn lại -> Học viên
        return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">Học viên</span>;
      }
    },
    {
      key: 'accountState',
      header: 'Trạng thái',
      render: (user) => (
        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${user.accountState
            ? 'bg-green-100 text-green-800'
            : 'bg-red-100 text-red-800'
          }`}>
          {user.accountState ? 'Active' : 'Bị Ban'}
        </span>
      ),
    },
    {
      key: 'enrollmentDate',
      header: 'Ngày tham gia',
      render: (user) => formatDate(user.enrollmentDate),
      sortable: true
    },
    {
      key: 'actions',
      header: 'Hành động',
      render: (user) => (
        <div className="flex space-x-2">
          {/* NÚT CHI TIẾT: Chuyển trang */}
          <Button
            size="sm"
            variant="secondary"
            onClick={() => navigate(`/users/${user.userID}`)}
          >
            <Eye className="w-4 h-4 mr-1" /> Chi tiết
          </Button>

          {/* NÚT XÓA: Mở Modal xác nhận (KHÔNG gọi API ngay) */}
          <Button
            size="sm"
            variant="danger"
            onClick={() => setUserToDelete(user)}
          >
            <Trash2 className="w-4 h-4" />
          </Button>
        </div>
      ),
    },
  ];

  return (
    <MainLayout>
      <h2 className="text-3xl font-bold text-gray-800 mb-6">Quản lý người dùng</h2>

      <div className="flex justify-between items-center mb-6 p-4 bg-white rounded-lg shadow-sm border border-gray-100">
        <div className="w-1/3 relative">
          <Input
            type="text"
            placeholder="Tìm kiếm theo tên, email..."
            icon={<Search className="w-5 h-5 text-gray-400" />}
            className="w-full pl-10"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <Button variant="primary" onClick={() => setIsModalOpen(true)}>
          <UserPlus className="w-5 h-5 mr-2" />
          Tạo đối tượng mới
        </Button>
      </div>

      {isLoading && (
        <div className="p-12 text-center flex flex-col items-center justify-center text-blue-600">
          <Loader2 className="w-8 h-8 animate-spin mb-2" />
          <span>Đang tải dữ liệu...</span>
        </div>
      )}

      {error && (
        <div className="p-6 text-center text-red-600 bg-red-50 rounded-lg border border-red-200">
          Lỗi kết nối: {error}
        </div>
      )}

      {!isLoading && fetchedUsers && (
        <>
          <Table<User>
            data={paginatedUsers}
            columns={userColumns}
            onSort={handleTableSort}
            sortKey={sortKey}
            sortDirection={sortDirection}
          />

          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            totalItems={totalItems}
            itemsPerPage={itemsPerPage}
            onPageChange={setCurrentPage}
          />
        </>
      )}

      {/* Modal Tạo mới */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Tạo Người dùng mới"
      >
        <UserForm
          onSubmit={handleCreateUser}
          onCancel={() => setIsModalOpen(false)}
          isSubmitting={isSubmitting}
        />
      </Modal>

      {/* Modal Xóa - QUAN TRỌNG: Nút này mới gọi API Xóa */}
      <Modal
        isOpen={!!userToDelete}
        onClose={() => setUserToDelete(null)}
        title="Xác nhận Xóa"
      >
        <div className="p-4">
          <p className="mb-4 text-gray-700">
            Bạn có chắc chắn muốn xóa người dùng <span className="font-bold">{userToDelete?.fullName}</span> ({userToDelete?.userID}) không?
            <br />Hành động này không thể hoàn tác.
          </p>
          <div className="flex justify-end space-x-3 mt-6">
            <Button variant="secondary" onClick={() => setUserToDelete(null)} disabled={isSubmitting}>Hủy</Button>

            {/* SỬA LẠI CHỖ NÀY: Gọi arrow function để truyền tham số userToDelete */}
            <Button
              variant="danger"
              isLoading={isSubmitting}
              onClick={() => userToDelete && handleDelete(userToDelete)}
            >
              {isSubmitting ? 'Đang xóa...' : 'Xác nhận Xóa'}
            </Button>
          </div>
        </div>
      </Modal>

    </MainLayout>
  );
};

export default UserList;