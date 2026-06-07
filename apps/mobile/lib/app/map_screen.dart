import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/models.dart';
import '../map/map.dart';
import 'map_view_controller.dart';
import 'share_moment_sheet.dart';
import 'theme.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({
    this.startPicking = false,
    this.editPinId,
    this.mapViewBuilder = buildOpenStreetMapView,
    super.key,
  });

  final bool startPicking;
  final String? editPinId;
  final MapViewWidgetBuilder mapViewBuilder;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late bool _isPicking = widget.startPicking;
  final int _bottomNavIndex = 0;
  Coordinates? _pickedCoordinates;

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startPicking != widget.startPicking ||
        oldWidget.editPinId != widget.editPinId) {
      _isPicking = widget.startPicking;
    }
  }

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        return;
      case 1:
        context.go('/timeline');
        return;
      case 2:
        context.go('/duo');
        return;
      case 3:
        context.go('/settings');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final MapViewState state = ref.watch(mapViewControllerProvider);
    final MapViewController controller =
        ref.read(mapViewControllerProvider.notifier);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: widget.mapViewBuilder(
              context,
              MapViewConfig(
                initialCamera: _initialCamera,
                markers: state.pins
                    .map(
                      (PinDto pin) => MapMarkerModel(
                        id: pin.id,
                        position: Coordinates(lat: pin.lat, lng: pin.lng),
                      ),
                    )
                    .toList(growable: false),
                onViewportChanged: controller.viewportChanged,
                onMarkerTap: (String pinId) {
                  final PinDto pin = state.pins.firstWhere(
                    (PinDto item) => item.id == pinId,
                  );
                  _showPinPreview(context, pin);
                },
                onTap: (Coordinates coordinates) {
                  if (_isPicking) {
                    setState(() {
                      _pickedCoordinates = coordinates;
                    });
                  }
                },
                onLongPress: (Coordinates coordinates) {
                  setState(() {
                    _isPicking = true;
                    _pickedCoordinates = coordinates;
                  });
                },
              ),
            ),
          ),
          if (_isPicking && _pickedCoordinates == null)
            const Center(
              child: Icon(
                Icons.add_location,
                size: 48,
                color: MemoTheme.primary,
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  if (_isPicking)
                    FloatingActionButton.small(
                      onPressed: () {
                        setState(() {
                          _isPicking = false;
                          _pickedCoordinates = null;
                        });
                      },
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.arrow_back,
                        color: MemoTheme.onBackground,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.map_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Bản đồ cá nhân',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.lock, size: 14),
                        ],
                      ),
                    ),
                  if (state.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: MemoTheme.danger,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cloud_off, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Đang offline',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: MemoTheme.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Đã đồng bộ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_isPicking)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_pickedCoordinates != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_pickedCoordinates!.lat.toStringAsFixed(5)}, ${_pickedCoordinates!.lng.toStringAsFixed(5)}',
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.my_location, size: 16),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Đặt ghim tại đây',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: MemoTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Giữ để chọn chính xác vị trí bạn muốn lưu.'),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _pickedCoordinates != null
                          ? () => _openPinEditor(context, _pickedCoordinates!)
                          : null,
                      icon: const Icon(Icons.location_on),
                      label: const Text('Tiếp tục'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isPicking = false;
                          _pickedCoordinates = null;
                        });
                      },
                      child: const Text(
                        'Hủy',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (state.errorMessage != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_outlined,
                      size: 32,
                      color: MemoTheme.primary,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hiển thị dữ liệu đã lưu',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Một số thay đổi của bạn sẽ được đồng bộ khi có mạng trở lại.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => controller.refresh(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(80, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh),
                          Text('Thử lại', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: _isPicking || state.errorMessage != null
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton(
                backgroundColor: MemoTheme.primary,
                foregroundColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _isPicking = true;
                    _pickedCoordinates = null;
                  });
                },
                child: const Icon(Icons.add, size: 32),
              ),
            ),
      bottomNavigationBar: _isPicking
          ? null
          : BottomNavigationBar(
              currentIndex: _bottomNavIndex,
              onTap: _onBottomNavTapped,
              selectedItemColor: MemoTheme.primary,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Bản đồ'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_time),
                  label: 'Dòng thời gian',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  label: 'Duo',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Cài đặt',
                ),
              ],
            ),
    );
  }

  void _showPinPreview(BuildContext context, PinDto pin) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quán nhỏ Đà Lạt',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '12 Thg 4, 2023',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Buổi sáng se lạnh, cà phê đậm và một góc nhỏ bình yên.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SheetAction(
                  icon: Icons.article_outlined,
                  label: 'Xem chi tiết',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/pins/${Uri.encodeComponent(pin.id)}');
                  },
                ),
                _SheetAction(
                  icon: Icons.location_on,
                  label: 'Xem trên bản đồ',
                  onTap: () => Navigator.pop(sheetContext),
                ),
                _SheetAction(
                  icon: Icons.share,
                  label: 'Chia sẻ',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) {
                        return;
                      }
                      _showShareSheet(context, pin);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context, PinDto pin) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ShareMomentSheet(pin: pin),
    );
  }

  void _openPinEditor(BuildContext context, Coordinates coordinates) {
    final Uri uri = Uri(
      path: widget.editPinId == null
          ? '/pins/new'
          : '/pins/${Uri.encodeComponent(widget.editPinId!)}/edit',
      queryParameters: <String, String>{
        'lat': coordinates.lat.toStringAsFixed(6),
        'lng': coordinates.lng.toStringAsFixed(6),
      },
    );
    context.push(uri.toString());
    setState(() {
      _isPicking = false;
    });
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MemoTheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

const MapCameraPosition _initialCamera = MapCameraPosition(
  center: Coordinates(lat: 11.35, lng: 107.58),
  zoom: 6.2,
);
