import 'dart:async';

import 'package:flutter/material.dart';

/// A function that returns a Future list of items, supporting pagination and search.
/// [page] is the current page number (starting from 1).
/// [query] is the search query.
typedef FutureRequest<T> = Future<List<T>> Function(int page, String? query);

/// A fully customizable dropdown widget with support for search, pagination (API or local),
/// multi-selection, and extensive styling options.
class CustomDropdown<T> extends StatefulWidget {
  /// The list of items to display (for local data).
  /// If [futureRequest] is provided, this is ignored (or used as initial data).
  final List<T>? items;

  /// A function to fetch items asynchronously (for API data).
  final FutureRequest<T>? futureRequest;

  /// The currently selected item (Single Selection Mode).
  final T? selectedItem;

  /// The currently selected items (Multi Selection Mode).
  final List<T>? selectedItems;

  /// Enable multi-selection mode.
  final bool enableMultiSelection;

  /// Enable/Disable the dropdown.
  final bool enabled;

  /// A function that returns the string representation of an item.
  /// Used in the default header and list item widgets.
  final String Function(T)? itemLabel;

  /// Callback when an item is selected (Single Selection Mode).
  final ValueChanged<T?>? onChanged;

  /// Callback when items are selected (Multi Selection Mode).
  final ValueChanged<List<T>>? onListChanged;

  /// Hint text to display when no item is selected.
  final String hintText;

  /// Hint text for the search field.
  final String searchHintText;

  /// Height of the dropdown overlay.
  final double dropdownHeight;

  /// Decoration for the dropdown header (the button).
  final BoxDecoration? headerDecoration;

  /// TextStyle for the dropdown header text.
  final TextStyle? headerTextStyle;

  /// Decoration for the dropdown overlay (the list).
  final BoxDecoration? dropdownDecoration;

  /// Decoration for the selected item in the list.
  final BoxDecoration? selectedItemDecoration;

  /// TextStyle for the items in the list.
  final TextStyle? listItemStyle;

  /// TextStyle for the selected item in the list.
  final TextStyle? selectedListItemStyle;

  /// Padding for the header.
  final EdgeInsetsGeometry? headerPadding;

  /// Padding for the list items.
  final EdgeInsetsGeometry? listItemPadding;

  /// Custom builder for the header (the button).
  final Widget Function(
    BuildContext context,
    T? selectedItem,
    List<T> selectedItems,
  )?
  headerBuilder;

  /// Custom builder for list items.
  final Widget Function(
    BuildContext context,
    T item,
    bool isSelected,
    VoidCallback onTap,
  )?
  listItemBuilder;

  /// Custom builder for the search field.
  final Widget Function(
    BuildContext context,
    TextEditingController controller,
    ValueChanged<String> onSearch,
  )?
  searchFieldBuilder;

  /// Widget to display when no items are found.
  final Widget? noResultFoundWidget;

  /// Widget to display when loading (initial or pagination).
  final Widget? loadingWidget;

  /// Widget to display when an error occurs.
  final Widget? errorWidget;

  /// Number of items to fetch per page (for API pagination).
  final int itemsPerPage;

  /// Debounce duration for search.
  final Duration searchDebounce;

  /// Text to verify / close multi-select dropdown.
  final String doneButtonText;

  /// Style for done button in multi-selection.
  final TextStyle? doneButtonStyle;

  const CustomDropdown({
    super.key,
    this.items,
    this.futureRequest,
    this.selectedItem,
    this.selectedItems,
    this.enableMultiSelection = false,
    this.enabled = true,
    this.itemLabel,
    this.onChanged,
    this.onListChanged,
    this.hintText = "Select",
    this.searchHintText = "Search...",
    this.dropdownHeight = 300,
    this.headerDecoration,
    this.headerTextStyle,
    this.dropdownDecoration,
    this.selectedItemDecoration,
    this.listItemStyle,
    this.selectedListItemStyle,
    this.headerPadding,
    this.listItemPadding,
    this.headerBuilder,
    this.listItemBuilder,
    this.searchFieldBuilder,
    this.noResultFoundWidget,
    this.loadingWidget,
    this.errorWidget,
    this.itemsPerPage = 10,
    this.searchDebounce = const Duration(milliseconds: 500),
    this.doneButtonText = "Done",
    this.doneButtonStyle,
  }) : assert(
         items != null || futureRequest != null,
         "Either items or futureRequest must be provided",
       );

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _key = GlobalKey();

  @override
  void dispose() {
    _removeDropdown();
    super.dispose();
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;

    if (_overlayEntry == null) {
      _showDropdown();
    } else {
      _removeDropdown();
    }
  }

  void _removeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showDropdown() {
    final renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    // Check space below
    final spaceBelow = screenHeight - (offset.dy + size.height);
    final showAbove =
        spaceBelow < widget.dropdownHeight && offset.dy > widget.dropdownHeight;

    final yOffset = showAbove ? -(widget.dropdownHeight + 6) : size.height + 6;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              // Background tap to close
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _removeDropdown,
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Dropdown content
              Positioned(
                width: size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0, yOffset),
                  child: _DropdownOverlay<T>(
                    height: widget.dropdownHeight,
                    items: widget.items,
                    futureRequest: widget.futureRequest,
                    selectedItem: widget.selectedItem,
                    selectedItems: widget.selectedItems ?? [],
                    enableMultiSelection: widget.enableMultiSelection,
                    itemLabel: widget.itemLabel,
                    onItemSelected: (value) {
                      if (widget.onChanged != null) {
                        widget.onChanged!(value);
                      }
                      _removeDropdown();
                    },
                    onListChanged: (values) {
                      if (widget.onListChanged != null) {
                        widget.onListChanged!(values);
                      }
                    },
                    decoration: widget.dropdownDecoration,
                    searchHintText: widget.searchHintText,
                    searchFieldBuilder: widget.searchFieldBuilder,
                    listItemBuilder: widget.listItemBuilder,
                    listItemStyle: widget.listItemStyle,
                    selectedListItemStyle: widget.selectedListItemStyle,
                    selectedItemDecoration: widget.selectedItemDecoration,
                    listItemPadding: widget.listItemPadding,
                    noResultFoundWidget: widget.noResultFoundWidget,
                    loadingWidget: widget.loadingWidget,
                    errorWidget: widget.errorWidget,
                    itemsPerPage: widget.itemsPerPage,
                    searchDebounce: widget.searchDebounce,
                    doneButtonText: widget.doneButtonText,
                    doneButtonStyle: widget.doneButtonStyle,
                    onDone: _removeDropdown,
                  ),
                ),
              ),
            ],
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    String headerText = widget.hintText;

    if (widget.enableMultiSelection) {
      if (widget.selectedItems != null && widget.selectedItems!.isNotEmpty) {
        headerText = widget.selectedItems!
            .map(
              (e) =>
                  widget.itemLabel != null
                      ? widget.itemLabel!(e)
                      : e.toString(),
            )
            .join(', ');
      }
    } else {
      if (widget.selectedItem != null) {
        headerText =
            widget.itemLabel != null
                ? widget.itemLabel!(widget.selectedItem as T)
                : widget.selectedItem.toString();
      }
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _key,
        onTap: _toggleDropdown,
        child:
            widget.headerBuilder != null
                ? widget.headerBuilder!(
                  context,
                  widget.selectedItem,
                  widget.selectedItems ?? [],
                )
                : Opacity(
                  opacity: widget.enabled ? 1.0 : 0.5,
                  child: Container(
                    padding:
                        widget.headerPadding ??
                        const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                    decoration:
                        widget.headerDecoration ??
                        BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            headerText,
                            style:
                                widget.headerTextStyle ??
                                const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}

class _DropdownOverlay<T> extends StatefulWidget {
  final List<T>? items;
  final FutureRequest<T>? futureRequest;
  final T? selectedItem;
  final List<T> selectedItems;
  final bool enableMultiSelection;
  final String Function(T)? itemLabel;
  final ValueChanged<T> onItemSelected;
  final ValueChanged<List<T>>? onListChanged;
  final double height;
  final BoxDecoration? decoration;
  final String searchHintText;
  final Widget Function(
    BuildContext,
    TextEditingController,
    ValueChanged<String>,
  )?
  searchFieldBuilder;
  final Widget Function(BuildContext, T, bool, VoidCallback)? listItemBuilder;
  final TextStyle? listItemStyle;
  final TextStyle? selectedListItemStyle;
  final BoxDecoration? selectedItemDecoration;
  final EdgeInsetsGeometry? listItemPadding;
  final Widget? noResultFoundWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final int itemsPerPage;
  final Duration searchDebounce;
  final String doneButtonText;
  final TextStyle? doneButtonStyle;
  final VoidCallback onDone;

  const _DropdownOverlay({
    required this.height,
    required this.onItemSelected,
    required this.searchHintText,
    required this.itemsPerPage,
    required this.searchDebounce,
    required this.selectedItems,
    required this.enableMultiSelection,
    required this.doneButtonText,
    required this.onDone,
    this.items,
    this.futureRequest,
    this.selectedItem,
    this.itemLabel,
    this.onListChanged,
    this.decoration,
    this.searchFieldBuilder,
    this.listItemBuilder,
    this.listItemStyle,
    this.selectedListItemStyle,
    this.selectedItemDecoration,
    this.listItemPadding,
    this.noResultFoundWidget,
    this.loadingWidget,
    this.errorWidget,
    this.doneButtonStyle,
  });

  @override
  State<_DropdownOverlay<T>> createState() => _DropdownOverlayState<T>();
}

class _DropdownOverlayState<T> extends State<_DropdownOverlay<T>>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  List<T> _displayedItems = [];
  late List<T> _tempSelectedItems;
  bool _isLoading = false;
  bool _hasError = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tempSelectedItems = List.from(widget.selectedItems);
    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_isLoading && _hasMore && widget.futureRequest != null) {
        _loadMore();
      }
    }
  }

  Future<void> _loadData({bool isSearch = false}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      List<T> newItems = [];

      if (widget.futureRequest != null) {
        // API Mode
        if (isSearch) {
          _currentPage = 1;
          _displayedItems.clear();
        }

        newItems = await widget.futureRequest!(_currentPage, _searchQuery);

        if (mounted) {
          setState(() {
            if (isSearch) {
              _displayedItems = newItems;
            } else {
              _displayedItems.addAll(newItems);
            }
            _hasMore = newItems.length >= widget.itemsPerPage;
          });
        }
      } else if (widget.items != null) {
        // Local Mode
        // Simulate search locally
        if (_searchQuery.isEmpty) {
          newItems = widget.items!;
        } else {
          newItems =
              widget.items!.where((item) {
                final label =
                    widget.itemLabel != null
                        ? widget.itemLabel!(item).toLowerCase()
                        : item.toString().toLowerCase();
                return label.contains(_searchQuery.toLowerCase());
              }).toList();
        }

        if (mounted) {
          setState(() {
            _displayedItems = newItems;
            _hasMore =
                false; // No pagination in local mode usually, or could implement "virtual" pagination
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    _currentPage++;
    await _loadData(isSearch: false);
  }

  void _onSearch(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(widget.searchDebounce, () {
      if (_searchQuery != value) {
        setState(
          () => _searchQuery = value,
        ); // Update state for clear button check
        _loadData(isSearch: true);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearch("");
  }

  void _onItemTapped(T item) {
    if (widget.enableMultiSelection) {
      setState(() {
        if (_tempSelectedItems.contains(item)) {
          _tempSelectedItems.remove(item);
        } else {
          _tempSelectedItems.add(item);
        }
      });
      if (widget.onListChanged != null) {
        widget.onListChanged!(_tempSelectedItems);
      }
    } else {
      widget.onItemSelected(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration:
                widget.decoration ??
                BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child:
                      widget.searchFieldBuilder != null
                          ? widget.searchFieldBuilder!(
                            context,
                            _searchController,
                            _onSearch,
                          )
                          : TextField(
                            controller: _searchController,
                            onChanged: _onSearch,
                            decoration: InputDecoration(
                              hintText: widget.searchHintText,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? GestureDetector(
                                        onTap: _clearSearch,
                                        child: const Icon(
                                          Icons.close,
                                          size: 20,
                                        ),
                                      )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                ),
                const SizedBox(height: 4),
                // List
                Expanded(child: _buildList()),
                // Done Button for MultiSelect
                if (widget.enableMultiSelection) _buildDoneButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoneButton() {
    return InkWell(
      onTap: widget.onDone,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Text(
          widget.doneButtonText,
          textAlign: TextAlign.center,
          style:
              widget.doneButtonStyle ??
              TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading && _displayedItems.isEmpty) {
      return Center(
        child: widget.loadingWidget ?? const CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child:
            widget.errorWidget ??
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Failed to load items"),
                TextButton(
                  onPressed: () => _loadData(isSearch: true),
                  child: const Text("Retry"),
                ),
              ],
            ),
      );
    }

    if (_displayedItems.isEmpty) {
      return Center(
        child: widget.noResultFoundWidget ?? const Text("No items found"),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: _displayedItems.length + (_isLoading && _hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _displayedItems.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  widget.loadingWidget ??
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
            ),
          );
        }

        final item = _displayedItems[index];
        final isSelected =
            widget.enableMultiSelection
                ? _tempSelectedItems.contains(item)
                : widget.selectedItem == item;

        if (widget.listItemBuilder != null) {
          return widget.listItemBuilder!(
            context,
            item,
            isSelected,
            () => _onItemTapped(item),
          );
        }

        // Default List Item
        return InkWell(
          onTap: () => _onItemTapped(item),
          child: Container(
            padding:
                widget.listItemPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration:
                isSelected &&
                        !widget
                            .enableMultiSelection // Only highlight bg for single select
                    ? (widget.selectedItemDecoration ??
                        BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                        ))
                    : null,
            child: Row(
              children: [
                if (widget.enableMultiSelection) // Checkbox for multi-select
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                      size: 20,
                    ),
                  ),
                Expanded(
                  child: Text(
                    widget.itemLabel != null
                        ? widget.itemLabel!(item)
                        : item.toString(),
                    style:
                        isSelected
                            ? (widget.selectedListItemStyle ??
                                const TextStyle(fontWeight: FontWeight.bold))
                            : (widget.listItemStyle ?? const TextStyle()),
                  ),
                ),
                if (isSelected && !widget.enableMultiSelection)
                  Icon(
                    Icons.check,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
