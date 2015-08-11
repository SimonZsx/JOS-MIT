
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 60 11 00       	mov    $0x116000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 89 11 f0       	mov    $0xf0118970,%eax
f010004b:	2d 00 83 11 f0       	sub    $0xf0118300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 83 11 f0 	movl   $0xf0118300,(%esp)
f0100063:	e8 9b 39 00 00       	call   f0103a03 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 7f 04 00 00       	call   f01004ec <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 e0 3e 10 f0 	movl   $0xf0103ee0,(%esp)
f010007c:	e8 59 2e 00 00       	call   f0102eda <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 f7 11 00 00       	call   f010127d <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 a0 07 00 00       	call   f0100832 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 89 11 f0 00 	cmpl   $0x0,0xf0118960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 89 11 f0    	mov    %esi,0xf0118960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 fb 3e 10 f0 	movl   $0xf0103efb,(%esp)
f01000c8:	e8 0d 2e 00 00       	call   f0102eda <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 ce 2d 00 00       	call   f0102ea7 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 94 4c 10 f0 	movl   $0xf0104c94,(%esp)
f01000e0:	e8 f5 2d 00 00       	call   f0102eda <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 41 07 00 00       	call   f0100832 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 13 3f 10 f0 	movl   $0xf0103f13,(%esp)
f0100112:	e8 c3 2d 00 00       	call   f0102eda <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 81 2d 00 00       	call   f0102ea7 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 94 4c 10 f0 	movl   $0xf0104c94,(%esp)
f010012d:	e8 a8 2d 00 00       	call   f0102eda <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
	...

f0100140 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba 84 00 00 00       	mov    $0x84,%edx
f0100148:	ec                   	in     (%dx),%al
f0100149:	ec                   	in     (%dx),%al
f010014a:	ec                   	in     (%dx),%al
f010014b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
f0100151:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100156:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100157:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 06                	je     f0100166 <serial_proc_data+0x18>
f0100160:	b2 f8                	mov    $0xf8,%dl
f0100162:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100163:	0f b6 c8             	movzbl %al,%ecx
}
f0100166:	89 c8                	mov    %ecx,%eax
f0100168:	5d                   	pop    %ebp
f0100169:	c3                   	ret    

f010016a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016a:	55                   	push   %ebp
f010016b:	89 e5                	mov    %esp,%ebp
f010016d:	53                   	push   %ebx
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100173:	eb 25                	jmp    f010019a <cons_intr+0x30>
		if (c == 0)
f0100175:	85 c0                	test   %eax,%eax
f0100177:	74 21                	je     f010019a <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f0100179:	8b 15 24 85 11 f0    	mov    0xf0118524,%edx
f010017f:	88 82 20 83 11 f0    	mov    %al,-0xfee7ce0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 24 85 11 f0       	mov    %eax,0xf0118524
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010019a:	ff d3                	call   *%ebx
f010019c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010019f:	75 d4                	jne    f0100175 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001a1:	83 c4 04             	add    $0x4,%esp
f01001a4:	5b                   	pop    %ebx
f01001a5:	5d                   	pop    %ebp
f01001a6:	c3                   	ret    

f01001a7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001a7:	55                   	push   %ebp
f01001a8:	89 e5                	mov    %esp,%ebp
f01001aa:	57                   	push   %edi
f01001ab:	56                   	push   %esi
f01001ac:	53                   	push   %ebx
f01001ad:	83 ec 2c             	sub    $0x2c,%esp
f01001b0:	89 c7                	mov    %eax,%edi
f01001b2:	bb 01 32 00 00       	mov    $0x3201,%ebx
f01001b7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01001bc:	eb 05                	jmp    f01001c3 <cons_putc+0x1c>
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001be:	e8 7d ff ff ff       	call   f0100140 <delay>
f01001c3:	89 f2                	mov    %esi,%edx
f01001c5:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001c6:	a8 20                	test   $0x20,%al
f01001c8:	75 05                	jne    f01001cf <cons_putc+0x28>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001ca:	83 eb 01             	sub    $0x1,%ebx
f01001cd:	75 ef                	jne    f01001be <cons_putc+0x17>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001cf:	89 fa                	mov    %edi,%edx
f01001d1:	89 f8                	mov    %edi,%eax
f01001d3:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001d6:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001db:	ee                   	out    %al,(%dx)
f01001dc:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e1:	be 79 03 00 00       	mov    $0x379,%esi
f01001e6:	eb 05                	jmp    f01001ed <cons_putc+0x46>
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
		delay();
f01001e8:	e8 53 ff ff ff       	call   f0100140 <delay>
f01001ed:	89 f2                	mov    %esi,%edx
f01001ef:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001f0:	84 c0                	test   %al,%al
f01001f2:	78 05                	js     f01001f9 <cons_putc+0x52>
f01001f4:	83 eb 01             	sub    $0x1,%ebx
f01001f7:	75 ef                	jne    f01001e8 <cons_putc+0x41>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001f9:	ba 78 03 00 00       	mov    $0x378,%edx
f01001fe:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100202:	ee                   	out    %al,(%dx)
f0100203:	b2 7a                	mov    $0x7a,%dl
f0100205:	b8 0d 00 00 00       	mov    $0xd,%eax
f010020a:	ee                   	out    %al,(%dx)
f010020b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100210:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100211:	89 fa                	mov    %edi,%edx
f0100213:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100219:	89 f8                	mov    %edi,%eax
f010021b:	80 cc 07             	or     $0x7,%ah
f010021e:	85 d2                	test   %edx,%edx
f0100220:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100223:	89 f8                	mov    %edi,%eax
f0100225:	25 ff 00 00 00       	and    $0xff,%eax
f010022a:	83 f8 09             	cmp    $0x9,%eax
f010022d:	74 79                	je     f01002a8 <cons_putc+0x101>
f010022f:	83 f8 09             	cmp    $0x9,%eax
f0100232:	7f 0e                	jg     f0100242 <cons_putc+0x9b>
f0100234:	83 f8 08             	cmp    $0x8,%eax
f0100237:	0f 85 9f 00 00 00    	jne    f01002dc <cons_putc+0x135>
f010023d:	8d 76 00             	lea    0x0(%esi),%esi
f0100240:	eb 10                	jmp    f0100252 <cons_putc+0xab>
f0100242:	83 f8 0a             	cmp    $0xa,%eax
f0100245:	74 3b                	je     f0100282 <cons_putc+0xdb>
f0100247:	83 f8 0d             	cmp    $0xd,%eax
f010024a:	0f 85 8c 00 00 00    	jne    f01002dc <cons_putc+0x135>
f0100250:	eb 38                	jmp    f010028a <cons_putc+0xe3>
	case '\b':
		if (crt_pos > 0) {
f0100252:	0f b7 05 34 85 11 f0 	movzwl 0xf0118534,%eax
f0100259:	66 85 c0             	test   %ax,%ax
f010025c:	0f 84 e4 00 00 00    	je     f0100346 <cons_putc+0x19f>
			crt_pos--;
f0100262:	83 e8 01             	sub    $0x1,%eax
f0100265:	66 a3 34 85 11 f0    	mov    %ax,0xf0118534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010026b:	0f b7 c0             	movzwl %ax,%eax
f010026e:	66 81 e7 00 ff       	and    $0xff00,%di
f0100273:	83 cf 20             	or     $0x20,%edi
f0100276:	8b 15 30 85 11 f0    	mov    0xf0118530,%edx
f010027c:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100280:	eb 77                	jmp    f01002f9 <cons_putc+0x152>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100282:	66 83 05 34 85 11 f0 	addw   $0x50,0xf0118534
f0100289:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010028a:	0f b7 05 34 85 11 f0 	movzwl 0xf0118534,%eax
f0100291:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100297:	c1 e8 16             	shr    $0x16,%eax
f010029a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010029d:	c1 e0 04             	shl    $0x4,%eax
f01002a0:	66 a3 34 85 11 f0    	mov    %ax,0xf0118534
f01002a6:	eb 51                	jmp    f01002f9 <cons_putc+0x152>
		break;
	case '\t':
		cons_putc(' ');
f01002a8:	b8 20 00 00 00       	mov    $0x20,%eax
f01002ad:	e8 f5 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002b2:	b8 20 00 00 00       	mov    $0x20,%eax
f01002b7:	e8 eb fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002bc:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c1:	e8 e1 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002c6:	b8 20 00 00 00       	mov    $0x20,%eax
f01002cb:	e8 d7 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002d0:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d5:	e8 cd fe ff ff       	call   f01001a7 <cons_putc>
f01002da:	eb 1d                	jmp    f01002f9 <cons_putc+0x152>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002dc:	0f b7 05 34 85 11 f0 	movzwl 0xf0118534,%eax
f01002e3:	0f b7 c8             	movzwl %ax,%ecx
f01002e6:	8b 15 30 85 11 f0    	mov    0xf0118530,%edx
f01002ec:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f01002f0:	83 c0 01             	add    $0x1,%eax
f01002f3:	66 a3 34 85 11 f0    	mov    %ax,0xf0118534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01002f9:	66 81 3d 34 85 11 f0 	cmpw   $0x7cf,0xf0118534
f0100300:	cf 07 
f0100302:	76 42                	jbe    f0100346 <cons_putc+0x19f>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100304:	a1 30 85 11 f0       	mov    0xf0118530,%eax
f0100309:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100310:	00 
f0100311:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100317:	89 54 24 04          	mov    %edx,0x4(%esp)
f010031b:	89 04 24             	mov    %eax,(%esp)
f010031e:	e8 3b 37 00 00       	call   f0103a5e <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100323:	8b 15 30 85 11 f0    	mov    0xf0118530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100329:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010032e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100334:	83 c0 01             	add    $0x1,%eax
f0100337:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010033c:	75 f0                	jne    f010032e <cons_putc+0x187>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010033e:	66 83 2d 34 85 11 f0 	subw   $0x50,0xf0118534
f0100345:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100346:	8b 0d 2c 85 11 f0    	mov    0xf011852c,%ecx
f010034c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100351:	89 ca                	mov    %ecx,%edx
f0100353:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100354:	0f b7 35 34 85 11 f0 	movzwl 0xf0118534,%esi
f010035b:	8d 59 01             	lea    0x1(%ecx),%ebx
f010035e:	89 f0                	mov    %esi,%eax
f0100360:	66 c1 e8 08          	shr    $0x8,%ax
f0100364:	89 da                	mov    %ebx,%edx
f0100366:	ee                   	out    %al,(%dx)
f0100367:	b8 0f 00 00 00       	mov    $0xf,%eax
f010036c:	89 ca                	mov    %ecx,%edx
f010036e:	ee                   	out    %al,(%dx)
f010036f:	89 f0                	mov    %esi,%eax
f0100371:	89 da                	mov    %ebx,%edx
f0100373:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100374:	83 c4 2c             	add    $0x2c,%esp
f0100377:	5b                   	pop    %ebx
f0100378:	5e                   	pop    %esi
f0100379:	5f                   	pop    %edi
f010037a:	5d                   	pop    %ebp
f010037b:	c3                   	ret    

f010037c <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010037c:	55                   	push   %ebp
f010037d:	89 e5                	mov    %esp,%ebp
f010037f:	53                   	push   %ebx
f0100380:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100383:	ba 64 00 00 00       	mov    $0x64,%edx
f0100388:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100389:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010038e:	a8 01                	test   $0x1,%al
f0100390:	0f 84 de 00 00 00    	je     f0100474 <kbd_proc_data+0xf8>
f0100396:	b2 60                	mov    $0x60,%dl
f0100398:	ec                   	in     (%dx),%al
f0100399:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010039b:	3c e0                	cmp    $0xe0,%al
f010039d:	75 11                	jne    f01003b0 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f010039f:	83 0d 28 85 11 f0 40 	orl    $0x40,0xf0118528
		return 0;
f01003a6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003ab:	e9 c4 00 00 00       	jmp    f0100474 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003b0:	84 c0                	test   %al,%al
f01003b2:	79 37                	jns    f01003eb <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003b4:	8b 0d 28 85 11 f0    	mov    0xf0118528,%ecx
f01003ba:	89 cb                	mov    %ecx,%ebx
f01003bc:	83 e3 40             	and    $0x40,%ebx
f01003bf:	83 e0 7f             	and    $0x7f,%eax
f01003c2:	85 db                	test   %ebx,%ebx
f01003c4:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003c7:	0f b6 d2             	movzbl %dl,%edx
f01003ca:	0f b6 82 60 3f 10 f0 	movzbl -0xfefc0a0(%edx),%eax
f01003d1:	83 c8 40             	or     $0x40,%eax
f01003d4:	0f b6 c0             	movzbl %al,%eax
f01003d7:	f7 d0                	not    %eax
f01003d9:	21 c1                	and    %eax,%ecx
f01003db:	89 0d 28 85 11 f0    	mov    %ecx,0xf0118528
		return 0;
f01003e1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003e6:	e9 89 00 00 00       	jmp    f0100474 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003eb:	8b 0d 28 85 11 f0    	mov    0xf0118528,%ecx
f01003f1:	f6 c1 40             	test   $0x40,%cl
f01003f4:	74 0e                	je     f0100404 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01003f6:	89 c2                	mov    %eax,%edx
f01003f8:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01003fb:	83 e1 bf             	and    $0xffffffbf,%ecx
f01003fe:	89 0d 28 85 11 f0    	mov    %ecx,0xf0118528
	}

	shift |= shiftcode[data];
f0100404:	0f b6 d2             	movzbl %dl,%edx
f0100407:	0f b6 82 60 3f 10 f0 	movzbl -0xfefc0a0(%edx),%eax
f010040e:	0b 05 28 85 11 f0    	or     0xf0118528,%eax
	shift ^= togglecode[data];
f0100414:	0f b6 8a 60 40 10 f0 	movzbl -0xfefbfa0(%edx),%ecx
f010041b:	31 c8                	xor    %ecx,%eax
f010041d:	a3 28 85 11 f0       	mov    %eax,0xf0118528

	c = charcode[shift & (CTL | SHIFT)][data];
f0100422:	89 c1                	mov    %eax,%ecx
f0100424:	83 e1 03             	and    $0x3,%ecx
f0100427:	8b 0c 8d 60 41 10 f0 	mov    -0xfefbea0(,%ecx,4),%ecx
f010042e:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100432:	a8 08                	test   $0x8,%al
f0100434:	74 19                	je     f010044f <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100436:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100439:	83 fa 19             	cmp    $0x19,%edx
f010043c:	77 05                	ja     f0100443 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010043e:	83 eb 20             	sub    $0x20,%ebx
f0100441:	eb 0c                	jmp    f010044f <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100443:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f0100446:	8d 53 20             	lea    0x20(%ebx),%edx
f0100449:	83 f9 19             	cmp    $0x19,%ecx
f010044c:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010044f:	f7 d0                	not    %eax
f0100451:	a8 06                	test   $0x6,%al
f0100453:	75 1f                	jne    f0100474 <kbd_proc_data+0xf8>
f0100455:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010045b:	75 17                	jne    f0100474 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f010045d:	c7 04 24 2d 3f 10 f0 	movl   $0xf0103f2d,(%esp)
f0100464:	e8 71 2a 00 00       	call   f0102eda <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100469:	ba 92 00 00 00       	mov    $0x92,%edx
f010046e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100473:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100474:	89 d8                	mov    %ebx,%eax
f0100476:	83 c4 14             	add    $0x14,%esp
f0100479:	5b                   	pop    %ebx
f010047a:	5d                   	pop    %ebp
f010047b:	c3                   	ret    

f010047c <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010047c:	55                   	push   %ebp
f010047d:	89 e5                	mov    %esp,%ebp
f010047f:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100482:	80 3d 00 83 11 f0 00 	cmpb   $0x0,0xf0118300
f0100489:	74 0a                	je     f0100495 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f010048b:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f0100490:	e8 d5 fc ff ff       	call   f010016a <cons_intr>
}
f0100495:	c9                   	leave  
f0100496:	c3                   	ret    

f0100497 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100497:	55                   	push   %ebp
f0100498:	89 e5                	mov    %esp,%ebp
f010049a:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010049d:	b8 7c 03 10 f0       	mov    $0xf010037c,%eax
f01004a2:	e8 c3 fc ff ff       	call   f010016a <cons_intr>
}
f01004a7:	c9                   	leave  
f01004a8:	c3                   	ret    

f01004a9 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004a9:	55                   	push   %ebp
f01004aa:	89 e5                	mov    %esp,%ebp
f01004ac:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004af:	e8 c8 ff ff ff       	call   f010047c <serial_intr>
	kbd_intr();
f01004b4:	e8 de ff ff ff       	call   f0100497 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004b9:	8b 15 20 85 11 f0    	mov    0xf0118520,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01004bf:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c4:	3b 15 24 85 11 f0    	cmp    0xf0118524,%edx
f01004ca:	74 1e                	je     f01004ea <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004cc:	0f b6 82 20 83 11 f0 	movzbl -0xfee7ce0(%edx),%eax
f01004d3:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004d6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004dc:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004e1:	0f 44 d1             	cmove  %ecx,%edx
f01004e4:	89 15 20 85 11 f0    	mov    %edx,0xf0118520
		return c;
	}
	return 0;
}
f01004ea:	c9                   	leave  
f01004eb:	c3                   	ret    

f01004ec <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ec:	55                   	push   %ebp
f01004ed:	89 e5                	mov    %esp,%ebp
f01004ef:	57                   	push   %edi
f01004f0:	56                   	push   %esi
f01004f1:	53                   	push   %ebx
f01004f2:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004f5:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01004fc:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100503:	5a a5 
	if (*cp != 0xA55A) {
f0100505:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010050c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100510:	74 11                	je     f0100523 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100512:	c7 05 2c 85 11 f0 b4 	movl   $0x3b4,0xf011852c
f0100519:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010051c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100521:	eb 16                	jmp    f0100539 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100523:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010052a:	c7 05 2c 85 11 f0 d4 	movl   $0x3d4,0xf011852c
f0100531:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100534:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100539:	8b 0d 2c 85 11 f0    	mov    0xf011852c,%ecx
f010053f:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100544:	89 ca                	mov    %ecx,%edx
f0100546:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100547:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010054a:	89 da                	mov    %ebx,%edx
f010054c:	ec                   	in     (%dx),%al
f010054d:	0f b6 f8             	movzbl %al,%edi
f0100550:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100553:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100558:	89 ca                	mov    %ecx,%edx
f010055a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055b:	89 da                	mov    %ebx,%edx
f010055d:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010055e:	89 35 30 85 11 f0    	mov    %esi,0xf0118530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100564:	0f b6 d8             	movzbl %al,%ebx
f0100567:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100569:	66 89 3d 34 85 11 f0 	mov    %di,0xf0118534
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100570:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100575:	b8 00 00 00 00       	mov    $0x0,%eax
f010057a:	89 da                	mov    %ebx,%edx
f010057c:	ee                   	out    %al,(%dx)
f010057d:	b2 fb                	mov    $0xfb,%dl
f010057f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100584:	ee                   	out    %al,(%dx)
f0100585:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f010058a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010058f:	89 ca                	mov    %ecx,%edx
f0100591:	ee                   	out    %al,(%dx)
f0100592:	b2 f9                	mov    $0xf9,%dl
f0100594:	b8 00 00 00 00       	mov    $0x0,%eax
f0100599:	ee                   	out    %al,(%dx)
f010059a:	b2 fb                	mov    $0xfb,%dl
f010059c:	b8 03 00 00 00       	mov    $0x3,%eax
f01005a1:	ee                   	out    %al,(%dx)
f01005a2:	b2 fc                	mov    $0xfc,%dl
f01005a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005a9:	ee                   	out    %al,(%dx)
f01005aa:	b2 f9                	mov    $0xf9,%dl
f01005ac:	b8 01 00 00 00       	mov    $0x1,%eax
f01005b1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b2:	b2 fd                	mov    $0xfd,%dl
f01005b4:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005b5:	3c ff                	cmp    $0xff,%al
f01005b7:	0f 95 c0             	setne  %al
f01005ba:	89 c6                	mov    %eax,%esi
f01005bc:	a2 00 83 11 f0       	mov    %al,0xf0118300
f01005c1:	89 da                	mov    %ebx,%edx
f01005c3:	ec                   	in     (%dx),%al
f01005c4:	89 ca                	mov    %ecx,%edx
f01005c6:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005c7:	89 f0                	mov    %esi,%eax
f01005c9:	84 c0                	test   %al,%al
f01005cb:	75 0c                	jne    f01005d9 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f01005cd:	c7 04 24 39 3f 10 f0 	movl   $0xf0103f39,(%esp)
f01005d4:	e8 01 29 00 00       	call   f0102eda <cprintf>
}
f01005d9:	83 c4 1c             	add    $0x1c,%esp
f01005dc:	5b                   	pop    %ebx
f01005dd:	5e                   	pop    %esi
f01005de:	5f                   	pop    %edi
f01005df:	5d                   	pop    %ebp
f01005e0:	c3                   	ret    

f01005e1 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005e1:	55                   	push   %ebp
f01005e2:	89 e5                	mov    %esp,%ebp
f01005e4:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01005ea:	e8 b8 fb ff ff       	call   f01001a7 <cons_putc>
}
f01005ef:	c9                   	leave  
f01005f0:	c3                   	ret    

f01005f1 <getchar>:

int
getchar(void)
{
f01005f1:	55                   	push   %ebp
f01005f2:	89 e5                	mov    %esp,%ebp
f01005f4:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01005f7:	e8 ad fe ff ff       	call   f01004a9 <cons_getc>
f01005fc:	85 c0                	test   %eax,%eax
f01005fe:	74 f7                	je     f01005f7 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <iscons>:

int
iscons(int fdnum)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100605:	b8 01 00 00 00       	mov    $0x1,%eax
f010060a:	5d                   	pop    %ebp
f010060b:	c3                   	ret    
f010060c:	00 00                	add    %al,(%eax)
	...

f0100610 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100616:	c7 04 24 70 41 10 f0 	movl   $0xf0104170,(%esp)
f010061d:	e8 b8 28 00 00       	call   f0102eda <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100622:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100629:	00 
f010062a:	c7 04 24 30 42 10 f0 	movl   $0xf0104230,(%esp)
f0100631:	e8 a4 28 00 00       	call   f0102eda <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100636:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010063d:	00 
f010063e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100645:	f0 
f0100646:	c7 04 24 58 42 10 f0 	movl   $0xf0104258,(%esp)
f010064d:	e8 88 28 00 00       	call   f0102eda <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100652:	c7 44 24 08 d5 3e 10 	movl   $0x103ed5,0x8(%esp)
f0100659:	00 
f010065a:	c7 44 24 04 d5 3e 10 	movl   $0xf0103ed5,0x4(%esp)
f0100661:	f0 
f0100662:	c7 04 24 7c 42 10 f0 	movl   $0xf010427c,(%esp)
f0100669:	e8 6c 28 00 00       	call   f0102eda <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010066e:	c7 44 24 08 00 83 11 	movl   $0x118300,0x8(%esp)
f0100675:	00 
f0100676:	c7 44 24 04 00 83 11 	movl   $0xf0118300,0x4(%esp)
f010067d:	f0 
f010067e:	c7 04 24 a0 42 10 f0 	movl   $0xf01042a0,(%esp)
f0100685:	e8 50 28 00 00       	call   f0102eda <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010068a:	c7 44 24 08 70 89 11 	movl   $0x118970,0x8(%esp)
f0100691:	00 
f0100692:	c7 44 24 04 70 89 11 	movl   $0xf0118970,0x4(%esp)
f0100699:	f0 
f010069a:	c7 04 24 c4 42 10 f0 	movl   $0xf01042c4,(%esp)
f01006a1:	e8 34 28 00 00       	call   f0102eda <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006a6:	b8 6f 8d 11 f0       	mov    $0xf0118d6f,%eax
f01006ab:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01006b0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006b5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006bb:	85 c0                	test   %eax,%eax
f01006bd:	0f 48 c2             	cmovs  %edx,%eax
f01006c0:	c1 f8 0a             	sar    $0xa,%eax
f01006c3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006c7:	c7 04 24 e8 42 10 f0 	movl   $0xf01042e8,(%esp)
f01006ce:	e8 07 28 00 00       	call   f0102eda <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d8:	c9                   	leave  
f01006d9:	c3                   	ret    

f01006da <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006da:	55                   	push   %ebp
f01006db:	89 e5                	mov    %esp,%ebp
f01006dd:	53                   	push   %ebx
f01006de:	83 ec 14             	sub    $0x14,%esp
f01006e1:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006e6:	8b 83 04 44 10 f0    	mov    -0xfefbbfc(%ebx),%eax
f01006ec:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006f0:	8b 83 00 44 10 f0    	mov    -0xfefbc00(%ebx),%eax
f01006f6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006fa:	c7 04 24 89 41 10 f0 	movl   $0xf0104189,(%esp)
f0100701:	e8 d4 27 00 00       	call   f0102eda <cprintf>
f0100706:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100709:	83 fb 24             	cmp    $0x24,%ebx
f010070c:	75 d8                	jne    f01006e6 <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010070e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100713:	83 c4 14             	add    $0x14,%esp
f0100716:	5b                   	pop    %ebx
f0100717:	5d                   	pop    %ebp
f0100718:	c3                   	ret    

f0100719 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100719:	55                   	push   %ebp
f010071a:	89 e5                	mov    %esp,%ebp
f010071c:	57                   	push   %edi
f010071d:	56                   	push   %esi
f010071e:	53                   	push   %ebx
f010071f:	83 ec 5c             	sub    $0x5c,%esp
	// Your code here.
	
	uint32_t *ebp, *eip;
	uint32_t arg[5];

	struct Eipdebuginfo info={0};
f0100722:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100727:	ba 18 00 00 00       	mov    $0x18,%edx
f010072c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100731:	89 4c 05 bc          	mov    %ecx,-0x44(%ebp,%eax,1)
f0100735:	83 c0 04             	add    $0x4,%eax
f0100738:	39 d0                	cmp    %edx,%eax
f010073a:	72 f5                	jb     f0100731 <mon_backtrace+0x18>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010073c:	89 e8                	mov    %ebp,%eax
f010073e:	89 c1                	mov    %eax,%ecx
	//info = (struct Eipdebuginfo *)malloc(sizeof(struct Eipdebuginfo));

	ebp = (uint32_t *)read_ebp();
f0100740:	89 c3                	mov    %eax,%ebx
	eip = (uint32_t *)*(ebp+1);
f0100742:	8b 70 04             	mov    0x4(%eax),%esi
	
	int i;
	for(i=0;i<5;i++){
f0100745:	b8 00 00 00 00       	mov    $0x0,%eax
		arg[i] = *(ebp+i+2);
f010074a:	8b 54 81 08          	mov    0x8(%ecx,%eax,4),%edx
f010074e:	89 54 85 d4          	mov    %edx,-0x2c(%ebp,%eax,4)

	ebp = (uint32_t *)read_ebp();
	eip = (uint32_t *)*(ebp+1);
	
	int i;
	for(i=0;i<5;i++){
f0100752:	83 c0 01             	add    $0x1,%eax
f0100755:	83 f8 05             	cmp    $0x5,%eax
f0100758:	75 f0                	jne    f010074a <mon_backtrace+0x31>
		arg[i] = *(ebp+i+2);
	}

	cprintf("Stack backtrace:\n");
f010075a:	c7 04 24 92 41 10 f0 	movl   $0xf0104192,(%esp)
f0100761:	e8 74 27 00 00       	call   f0102eda <cprintf>

	while(ebp){
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip, arg[0], arg[1], arg[2], arg[3], arg[4]);

		debuginfo_eip((uintptr_t) eip, &info);
f0100766:	8d 7d bc             	lea    -0x44(%ebp),%edi
		arg[i] = *(ebp+i+2);
	}

	cprintf("Stack backtrace:\n");

	while(ebp){
f0100769:	e9 af 00 00 00       	jmp    f010081d <mon_backtrace+0x104>
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip, arg[0], arg[1], arg[2], arg[3], arg[4]);
f010076e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100771:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100775:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100778:	89 44 24 18          	mov    %eax,0x18(%esp)
f010077c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010077f:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100783:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100786:	89 44 24 10          	mov    %eax,0x10(%esp)
f010078a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010078d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100791:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100795:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100799:	c7 04 24 14 43 10 f0 	movl   $0xf0104314,(%esp)
f01007a0:	e8 35 27 00 00       	call   f0102eda <cprintf>

		debuginfo_eip((uintptr_t) eip, &info);
f01007a5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007a9:	89 34 24             	mov    %esi,(%esp)
f01007ac:	e8 2f 28 00 00       	call   f0102fe0 <debuginfo_eip>

		char *fname="";
		memcpy(fname, info.eip_fn_name, info.eip_fn_namelen);
f01007b1:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01007b4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007b8:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01007bb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007bf:	c7 04 24 95 4c 10 f0 	movl   $0xf0104c95,(%esp)
f01007c6:	e8 0c 33 00 00       	call   f0103ad7 <memcpy>
		fname[info.eip_fn_namelen]='\0';
f01007cb:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01007ce:	c6 80 95 4c 10 f0 00 	movb   $0x0,-0xfefb36b(%eax)
		
		cprintf("         %s:%d: %s+%d\n", info.eip_file, info.eip_line, fname, 4*(eip-(uint32_t *)info.eip_fn_addr));
f01007d5:	2b 75 cc             	sub    -0x34(%ebp),%esi
f01007d8:	83 e6 fc             	and    $0xfffffffc,%esi
f01007db:	89 74 24 10          	mov    %esi,0x10(%esp)
f01007df:	c7 44 24 0c 95 4c 10 	movl   $0xf0104c95,0xc(%esp)
f01007e6:	f0 
f01007e7:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01007ea:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007ee:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01007f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f5:	c7 04 24 a4 41 10 f0 	movl   $0xf01041a4,(%esp)
f01007fc:	e8 d9 26 00 00       	call   f0102eda <cprintf>
		ebp = (uint32_t *)*(ebp);
f0100801:	8b 1b                	mov    (%ebx),%ebx
f0100803:	89 d9                	mov    %ebx,%ecx
		eip = (uint32_t *)*(ebp+1);
f0100805:	8b 73 04             	mov    0x4(%ebx),%esi
		int i;
		for(i=0;i<5;i++){
f0100808:	b8 00 00 00 00       	mov    $0x0,%eax
			arg[i] = *(ebp+i+2);
f010080d:	8b 54 81 08          	mov    0x8(%ecx,%eax,4),%edx
f0100811:	89 54 85 d4          	mov    %edx,-0x2c(%ebp,%eax,4)
		
		cprintf("         %s:%d: %s+%d\n", info.eip_file, info.eip_line, fname, 4*(eip-(uint32_t *)info.eip_fn_addr));
		ebp = (uint32_t *)*(ebp);
		eip = (uint32_t *)*(ebp+1);
		int i;
		for(i=0;i<5;i++){
f0100815:	83 c0 01             	add    $0x1,%eax
f0100818:	83 f8 05             	cmp    $0x5,%eax
f010081b:	75 f0                	jne    f010080d <mon_backtrace+0xf4>
		arg[i] = *(ebp+i+2);
	}

	cprintf("Stack backtrace:\n");

	while(ebp){
f010081d:	85 db                	test   %ebx,%ebx
f010081f:	0f 85 49 ff ff ff    	jne    f010076e <mon_backtrace+0x55>
			arg[i] = *(ebp+i+2);
		}
	}
	
	return 0;
}
f0100825:	b8 00 00 00 00       	mov    $0x0,%eax
f010082a:	83 c4 5c             	add    $0x5c,%esp
f010082d:	5b                   	pop    %ebx
f010082e:	5e                   	pop    %esi
f010082f:	5f                   	pop    %edi
f0100830:	5d                   	pop    %ebp
f0100831:	c3                   	ret    

f0100832 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100832:	55                   	push   %ebp
f0100833:	89 e5                	mov    %esp,%ebp
f0100835:	57                   	push   %edi
f0100836:	56                   	push   %esi
f0100837:	53                   	push   %ebx
f0100838:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010083b:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100842:	e8 93 26 00 00       	call   f0102eda <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100847:	c7 04 24 70 43 10 f0 	movl   $0xf0104370,(%esp)
f010084e:	e8 87 26 00 00       	call   f0102eda <cprintf>
    //cprintf("H%x Wo%s", 57616, &i);

	//cprintf("x=%d y=%d", 3);

	while (1) {
		buf = readline("K> ");
f0100853:	c7 04 24 bb 41 10 f0 	movl   $0xf01041bb,(%esp)
f010085a:	e8 51 2f 00 00       	call   f01037b0 <readline>
f010085f:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100861:	85 c0                	test   %eax,%eax
f0100863:	74 ee                	je     f0100853 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100865:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010086c:	be 00 00 00 00       	mov    $0x0,%esi
f0100871:	eb 06                	jmp    f0100879 <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100873:	c6 03 00             	movb   $0x0,(%ebx)
f0100876:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100879:	0f b6 03             	movzbl (%ebx),%eax
f010087c:	84 c0                	test   %al,%al
f010087e:	74 64                	je     f01008e4 <monitor+0xb2>
f0100880:	0f be c0             	movsbl %al,%eax
f0100883:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100887:	c7 04 24 bf 41 10 f0 	movl   $0xf01041bf,(%esp)
f010088e:	e8 33 31 00 00       	call   f01039c6 <strchr>
f0100893:	85 c0                	test   %eax,%eax
f0100895:	75 dc                	jne    f0100873 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100897:	80 3b 00             	cmpb   $0x0,(%ebx)
f010089a:	74 48                	je     f01008e4 <monitor+0xb2>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010089c:	83 fe 0f             	cmp    $0xf,%esi
f010089f:	90                   	nop
f01008a0:	75 16                	jne    f01008b8 <monitor+0x86>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008a2:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008a9:	00 
f01008aa:	c7 04 24 c4 41 10 f0 	movl   $0xf01041c4,(%esp)
f01008b1:	e8 24 26 00 00       	call   f0102eda <cprintf>
f01008b6:	eb 9b                	jmp    f0100853 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008b8:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008bc:	83 c6 01             	add    $0x1,%esi
f01008bf:	eb 03                	jmp    f01008c4 <monitor+0x92>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008c1:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008c4:	0f b6 03             	movzbl (%ebx),%eax
f01008c7:	84 c0                	test   %al,%al
f01008c9:	74 ae                	je     f0100879 <monitor+0x47>
f01008cb:	0f be c0             	movsbl %al,%eax
f01008ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d2:	c7 04 24 bf 41 10 f0 	movl   $0xf01041bf,(%esp)
f01008d9:	e8 e8 30 00 00       	call   f01039c6 <strchr>
f01008de:	85 c0                	test   %eax,%eax
f01008e0:	74 df                	je     f01008c1 <monitor+0x8f>
f01008e2:	eb 95                	jmp    f0100879 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f01008e4:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008eb:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008ec:	85 f6                	test   %esi,%esi
f01008ee:	0f 84 5f ff ff ff    	je     f0100853 <monitor+0x21>
f01008f4:	bb 00 44 10 f0       	mov    $0xf0104400,%ebx
f01008f9:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008fe:	8b 03                	mov    (%ebx),%eax
f0100900:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100904:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100907:	89 04 24             	mov    %eax,(%esp)
f010090a:	e8 58 30 00 00       	call   f0103967 <strcmp>
f010090f:	85 c0                	test   %eax,%eax
f0100911:	75 24                	jne    f0100937 <monitor+0x105>
			return commands[i].func(argc, argv, tf);
f0100913:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100916:	8b 55 08             	mov    0x8(%ebp),%edx
f0100919:	89 54 24 08          	mov    %edx,0x8(%esp)
f010091d:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100920:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100924:	89 34 24             	mov    %esi,(%esp)
f0100927:	ff 14 85 08 44 10 f0 	call   *-0xfefbbf8(,%eax,4)
	//cprintf("x=%d y=%d", 3);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010092e:	85 c0                	test   %eax,%eax
f0100930:	78 28                	js     f010095a <monitor+0x128>
f0100932:	e9 1c ff ff ff       	jmp    f0100853 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100937:	83 c7 01             	add    $0x1,%edi
f010093a:	83 c3 0c             	add    $0xc,%ebx
f010093d:	83 ff 03             	cmp    $0x3,%edi
f0100940:	75 bc                	jne    f01008fe <monitor+0xcc>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100942:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100945:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100949:	c7 04 24 e1 41 10 f0 	movl   $0xf01041e1,(%esp)
f0100950:	e8 85 25 00 00       	call   f0102eda <cprintf>
f0100955:	e9 f9 fe ff ff       	jmp    f0100853 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010095a:	83 c4 5c             	add    $0x5c,%esp
f010095d:	5b                   	pop    %ebx
f010095e:	5e                   	pop    %esi
f010095f:	5f                   	pop    %edi
f0100960:	5d                   	pop    %ebp
f0100961:	c3                   	ret    
	...

f0100964 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100964:	55                   	push   %ebp
f0100965:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100967:	83 3d 3c 85 11 f0 00 	cmpl   $0x0,0xf011853c
f010096e:	75 11                	jne    f0100981 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100970:	ba 6f 99 11 f0       	mov    $0xf011996f,%edx
f0100975:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010097b:	89 15 3c 85 11 f0    	mov    %edx,0xf011853c
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	result = nextfree;
f0100981:	8b 15 3c 85 11 f0    	mov    0xf011853c,%edx

	nextfree += ROUNDUP(n, PGSIZE);
f0100987:	05 ff 0f 00 00       	add    $0xfff,%eax
f010098c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100991:	01 d0                	add    %edx,%eax
f0100993:	a3 3c 85 11 f0       	mov    %eax,0xf011853c

	return result;
}
f0100998:	89 d0                	mov    %edx,%eax
f010099a:	5d                   	pop    %ebp
f010099b:	c3                   	ret    

f010099c <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010099c:	55                   	push   %ebp
f010099d:	89 e5                	mov    %esp,%ebp
f010099f:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01009a2:	89 d1                	mov    %edx,%ecx
f01009a4:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f01009a7:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f01009aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f01009af:	f6 c1 01             	test   $0x1,%cl
f01009b2:	74 57                	je     f0100a0b <check_va2pa+0x6f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009b4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009ba:	89 c8                	mov    %ecx,%eax
f01009bc:	c1 e8 0c             	shr    $0xc,%eax
f01009bf:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f01009c5:	72 20                	jb     f01009e7 <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009c7:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01009cb:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f01009d2:	f0 
f01009d3:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f01009da:	00 
f01009db:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01009e2:	e8 ad f6 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f01009e7:	c1 ea 0c             	shr    $0xc,%edx
f01009ea:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009f0:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f01009f7:	89 c2                	mov    %eax,%edx
f01009f9:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009fc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a01:	85 d2                	test   %edx,%edx
f0100a03:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a08:	0f 44 c2             	cmove  %edx,%eax
}
f0100a0b:	c9                   	leave  
f0100a0c:	c3                   	ret    

f0100a0d <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a0d:	55                   	push   %ebp
f0100a0e:	89 e5                	mov    %esp,%ebp
f0100a10:	83 ec 18             	sub    $0x18,%esp
f0100a13:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a16:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a19:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a1b:	89 04 24             	mov    %eax,(%esp)
f0100a1e:	e8 49 24 00 00       	call   f0102e6c <mc146818_read>
f0100a23:	89 c6                	mov    %eax,%esi
f0100a25:	83 c3 01             	add    $0x1,%ebx
f0100a28:	89 1c 24             	mov    %ebx,(%esp)
f0100a2b:	e8 3c 24 00 00       	call   f0102e6c <mc146818_read>
f0100a30:	c1 e0 08             	shl    $0x8,%eax
f0100a33:	09 f0                	or     %esi,%eax
}
f0100a35:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a38:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a3b:	89 ec                	mov    %ebp,%esp
f0100a3d:	5d                   	pop    %ebp
f0100a3e:	c3                   	ret    

f0100a3f <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a3f:	55                   	push   %ebp
f0100a40:	89 e5                	mov    %esp,%ebp
f0100a42:	57                   	push   %edi
f0100a43:	56                   	push   %esi
f0100a44:	53                   	push   %ebx
f0100a45:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a48:	3c 01                	cmp    $0x1,%al
f0100a4a:	19 f6                	sbb    %esi,%esi
f0100a4c:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100a52:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100a55:	8b 15 40 85 11 f0    	mov    0xf0118540,%edx
f0100a5b:	85 d2                	test   %edx,%edx
f0100a5d:	75 1c                	jne    f0100a7b <check_page_free_list+0x3c>
		panic("'page_free_list' is a null pointer!");
f0100a5f:	c7 44 24 08 48 44 10 	movl   $0xf0104448,0x8(%esp)
f0100a66:	f0 
f0100a67:	c7 44 24 04 4f 02 00 	movl   $0x24f,0x4(%esp)
f0100a6e:	00 
f0100a6f:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100a76:	e8 19 f6 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f0100a7b:	84 c0                	test   %al,%al
f0100a7d:	74 4b                	je     f0100aca <check_page_free_list+0x8b>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a7f:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100a82:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100a85:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100a88:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a8b:	89 d0                	mov    %edx,%eax
f0100a8d:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0100a93:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a96:	c1 e8 16             	shr    $0x16,%eax
f0100a99:	39 c6                	cmp    %eax,%esi
f0100a9b:	0f 96 c0             	setbe  %al
f0100a9e:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100aa1:	8b 4c 85 d8          	mov    -0x28(%ebp,%eax,4),%ecx
f0100aa5:	89 11                	mov    %edx,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100aa7:	89 54 85 d8          	mov    %edx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aab:	8b 12                	mov    (%edx),%edx
f0100aad:	85 d2                	test   %edx,%edx
f0100aaf:	75 da                	jne    f0100a8b <check_page_free_list+0x4c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ab1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ab4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100aba:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100abd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ac0:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ac2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ac5:	a3 40 85 11 f0       	mov    %eax,0xf0118540
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100aca:	8b 1d 40 85 11 f0    	mov    0xf0118540,%ebx
f0100ad0:	eb 63                	jmp    f0100b35 <check_page_free_list+0xf6>
f0100ad2:	89 d8                	mov    %ebx,%eax
f0100ad4:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0100ada:	c1 f8 03             	sar    $0x3,%eax
f0100add:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ae0:	89 c2                	mov    %eax,%edx
f0100ae2:	c1 ea 16             	shr    $0x16,%edx
f0100ae5:	39 d6                	cmp    %edx,%esi
f0100ae7:	76 4a                	jbe    f0100b33 <check_page_free_list+0xf4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ae9:	89 c2                	mov    %eax,%edx
f0100aeb:	c1 ea 0c             	shr    $0xc,%edx
f0100aee:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100af4:	72 20                	jb     f0100b16 <check_page_free_list+0xd7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100af6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100afa:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f0100b01:	f0 
f0100b02:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b09:	00 
f0100b0a:	c7 04 24 e0 4b 10 f0 	movl   $0xf0104be0,(%esp)
f0100b11:	e8 7e f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b16:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b1d:	00 
f0100b1e:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b25:	00 
	return (void *)(pa + KERNBASE);
f0100b26:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b2b:	89 04 24             	mov    %eax,(%esp)
f0100b2e:	e8 d0 2e 00 00       	call   f0103a03 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b33:	8b 1b                	mov    (%ebx),%ebx
f0100b35:	85 db                	test   %ebx,%ebx
f0100b37:	75 99                	jne    f0100ad2 <check_page_free_list+0x93>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b39:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b3e:	e8 21 fe ff ff       	call   f0100964 <boot_alloc>
f0100b43:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b46:	8b 15 40 85 11 f0    	mov    0xf0118540,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b4c:	8b 0d 6c 89 11 f0    	mov    0xf011896c,%ecx
		assert(pp < pages + npages);
f0100b52:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0100b57:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b5a:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b5d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b60:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b63:	be 00 00 00 00       	mov    $0x0,%esi
f0100b68:	89 4d c0             	mov    %ecx,-0x40(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b6b:	e9 97 01 00 00       	jmp    f0100d07 <check_page_free_list+0x2c8>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b70:	3b 55 c0             	cmp    -0x40(%ebp),%edx
f0100b73:	73 24                	jae    f0100b99 <check_page_free_list+0x15a>
f0100b75:	c7 44 24 0c ee 4b 10 	movl   $0xf0104bee,0xc(%esp)
f0100b7c:	f0 
f0100b7d:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0100b84:	f0 
f0100b85:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f0100b8c:	00 
f0100b8d:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100b94:	e8 fb f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100b99:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100b9c:	72 24                	jb     f0100bc2 <check_page_free_list+0x183>
f0100b9e:	c7 44 24 0c 0f 4c 10 	movl   $0xf0104c0f,0xc(%esp)
f0100ba5:	f0 
f0100ba6:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0100bad:	f0 
f0100bae:	c7 44 24 04 6a 02 00 	movl   $0x26a,0x4(%esp)
f0100bb5:	00 
f0100bb6:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100bbd:	e8 d2 f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bc2:	89 d0                	mov    %edx,%eax
f0100bc4:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bc7:	a8 07                	test   $0x7,%al
f0100bc9:	74 24                	je     f0100bef <check_page_free_list+0x1b0>
f0100bcb:	c7 44 24 0c 6c 44 10 	movl   $0xf010446c,0xc(%esp)
f0100bd2:	f0 
f0100bd3:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0100bda:	f0 
f0100bdb:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f0100be2:	00 
f0100be3:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100bea:	e8 a5 f4 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bef:	c1 f8 03             	sar    $0x3,%eax
f0100bf2:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100bf5:	85 c0                	test   %eax,%eax
f0100bf7:	75 24                	jne    f0100c1d <check_page_free_list+0x1de>
f0100bf9:	c7 44 24 0c 23 4c 10 	movl   $0xf0104c23,0xc(%esp)
f0100c00:	f0 
f0100c01:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0100c08:	f0 
f0100c09:	c7 44 24 04 6e 02 00 	movl   $0x26e,0x4(%esp)
f0100c10:	00 
f0100c11:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100c18:	e8 77 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c1d:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c22:	75 24                	jne    f0100c48 <check_page_free_list+0x209>
f0100c24:	c7 44 24 0c 34 4c 10 	movl   $0xf0104c34,0xc(%esp)
f0100c2b:	f0 
f0100c2c:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0100c33:	f0 
f0100c34:	c7 44 24 04 6f 02 00 	movl   $0x26f,0x4(%esp)
f0100c3b:	00 
f0100c3c:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100c43:	e8 4c f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c48:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c4d:	75 24                	jne    f0100c73 <check_page_free_list+0x234>
f0100c4f:	c7 44 24 0c a0 44 10 	movl   $0xf01044a0,0xc(%esp)
f0100c56:	f0 
f0100c57:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0100c5e:	f0 
f0100c5f:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f0100c66:	00 
f0100c67:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100c6e:	e8 21 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c73:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c78:	75 24                	jne    f0100c9e <check_page_free_list+0x25f>
f0100c7a:	c7 44 24 0c 4d 4c 10 	movl   $0xf0104c4d,0xc(%esp)
f0100c81:	f0 
f0100c82:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0100c89:	f0 
f0100c8a:	c7 44 24 04 71 02 00 	movl   $0x271,0x4(%esp)
f0100c91:	00 
f0100c92:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100c99:	e8 f6 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c9e:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100ca3:	76 58                	jbe    f0100cfd <check_page_free_list+0x2be>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ca5:	89 c1                	mov    %eax,%ecx
f0100ca7:	c1 e9 0c             	shr    $0xc,%ecx
f0100caa:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100cad:	77 20                	ja     f0100ccf <check_page_free_list+0x290>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100caf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cb3:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f0100cba:	f0 
f0100cbb:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100cc2:	00 
f0100cc3:	c7 04 24 e0 4b 10 f0 	movl   $0xf0104be0,(%esp)
f0100cca:	e8 c5 f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100ccf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cd4:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100cd7:	76 29                	jbe    f0100d02 <check_page_free_list+0x2c3>
f0100cd9:	c7 44 24 0c c4 44 10 	movl   $0xf01044c4,0xc(%esp)
f0100ce0:	f0 
f0100ce1:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0100ce8:	f0 
f0100ce9:	c7 44 24 04 72 02 00 	movl   $0x272,0x4(%esp)
f0100cf0:	00 
f0100cf1:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100cf8:	e8 97 f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100cfd:	83 c6 01             	add    $0x1,%esi
f0100d00:	eb 03                	jmp    f0100d05 <check_page_free_list+0x2c6>
		else
			++nfree_extmem;
f0100d02:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d05:	8b 12                	mov    (%edx),%edx
f0100d07:	85 d2                	test   %edx,%edx
f0100d09:	0f 85 61 fe ff ff    	jne    f0100b70 <check_page_free_list+0x131>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d0f:	85 f6                	test   %esi,%esi
f0100d11:	7f 24                	jg     f0100d37 <check_page_free_list+0x2f8>
f0100d13:	c7 44 24 0c 67 4c 10 	movl   $0xf0104c67,0xc(%esp)
f0100d1a:	f0 
f0100d1b:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0100d22:	f0 
f0100d23:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f0100d2a:	00 
f0100d2b:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100d32:	e8 5d f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d37:	85 db                	test   %ebx,%ebx
f0100d39:	7f 24                	jg     f0100d5f <check_page_free_list+0x320>
f0100d3b:	c7 44 24 0c 79 4c 10 	movl   $0xf0104c79,0xc(%esp)
f0100d42:	f0 
f0100d43:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0100d4a:	f0 
f0100d4b:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f0100d52:	00 
f0100d53:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100d5a:	e8 35 f3 ff ff       	call   f0100094 <_panic>
}
f0100d5f:	83 c4 4c             	add    $0x4c,%esp
f0100d62:	5b                   	pop    %ebx
f0100d63:	5e                   	pop    %esi
f0100d64:	5f                   	pop    %edi
f0100d65:	5d                   	pop    %ebp
f0100d66:	c3                   	ret    

f0100d67 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100d67:	55                   	push   %ebp
f0100d68:	89 e5                	mov    %esp,%ebp
f0100d6a:	56                   	push   %esi
f0100d6b:	53                   	push   %ebx
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;

	uint32_t pa;
    page_free_list = NULL;
f0100d6c:	c7 05 40 85 11 f0 00 	movl   $0x0,0xf0118540
f0100d73:	00 00 00 

	for (i = 0; i < npages; i++) {
f0100d76:	be 00 00 00 00       	mov    $0x0,%esi
f0100d7b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d80:	e9 a2 00 00 00       	jmp    f0100e27 <page_init+0xc0>

		if(i == 0){
f0100d85:	85 db                	test   %ebx,%ebx
f0100d87:	75 16                	jne    f0100d9f <page_init+0x38>
			pages[i].pp_ref=1;
f0100d89:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100d8e:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link=NULL;
f0100d94:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100d9a:	e9 82 00 00 00       	jmp    f0100e21 <page_init+0xba>
		}
		else if(i < npages_basemem){
f0100d9f:	3b 1d 38 85 11 f0    	cmp    0xf0118538,%ebx
f0100da5:	73 24                	jae    f0100dcb <page_init+0x64>
			pages[i].pp_ref = 0;
f0100da7:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100dac:	66 c7 44 30 04 00 00 	movw   $0x0,0x4(%eax,%esi,1)
			pages[i].pp_link = page_free_list;
f0100db3:	8b 15 40 85 11 f0    	mov    0xf0118540,%edx
f0100db9:	89 14 30             	mov    %edx,(%eax,%esi,1)
			page_free_list = &pages[i];
f0100dbc:	89 f0                	mov    %esi,%eax
f0100dbe:	03 05 6c 89 11 f0    	add    0xf011896c,%eax
f0100dc4:	a3 40 85 11 f0       	mov    %eax,0xf0118540
f0100dc9:	eb 56                	jmp    f0100e21 <page_init+0xba>
		}
		else if(i<=EXTPHYSMEM/PGSIZE || i < (((uint32_t)boot_alloc(0) - KERNBASE) >> PGSHIFT) )
f0100dcb:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
f0100dd1:	76 16                	jbe    f0100de9 <page_init+0x82>
f0100dd3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dd8:	e8 87 fb ff ff       	call   f0100964 <boot_alloc>
f0100ddd:	05 00 00 00 10       	add    $0x10000000,%eax
f0100de2:	c1 e8 0c             	shr    $0xc,%eax
f0100de5:	39 c3                	cmp    %eax,%ebx
f0100de7:	73 15                	jae    f0100dfe <page_init+0x97>
		{
			pages[i].pp_ref ++;
f0100de9:	89 f0                	mov    %esi,%eax
f0100deb:	03 05 6c 89 11 f0    	add    0xf011896c,%eax
f0100df1:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100df6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100dfc:	eb 23                	jmp    f0100e21 <page_init+0xba>
		}
		else{
			pages[i].pp_ref = 0;
f0100dfe:	89 f0                	mov    %esi,%eax
f0100e00:	03 05 6c 89 11 f0    	add    0xf011896c,%eax
f0100e06:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100e0c:	8b 15 40 85 11 f0    	mov    0xf0118540,%edx
f0100e12:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100e14:	89 f0                	mov    %esi,%eax
f0100e16:	03 05 6c 89 11 f0    	add    0xf011896c,%eax
f0100e1c:	a3 40 85 11 f0       	mov    %eax,0xf0118540
	size_t i;

	uint32_t pa;
    page_free_list = NULL;

	for (i = 0; i < npages; i++) {
f0100e21:	83 c3 01             	add    $0x1,%ebx
f0100e24:	83 c6 08             	add    $0x8,%esi
f0100e27:	3b 1d 64 89 11 f0    	cmp    0xf0118964,%ebx
f0100e2d:	0f 82 52 ff ff ff    	jb     f0100d85 <page_init+0x1e>
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}

	}
}
f0100e33:	5b                   	pop    %ebx
f0100e34:	5e                   	pop    %esi
f0100e35:	5d                   	pop    %ebp
f0100e36:	c3                   	ret    

f0100e37 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100e37:	55                   	push   %ebp
f0100e38:	89 e5                	mov    %esp,%ebp
f0100e3a:	53                   	push   %ebx
f0100e3b:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if(!page_free_list){
f0100e3e:	8b 1d 40 85 11 f0    	mov    0xf0118540,%ebx
f0100e44:	85 db                	test   %ebx,%ebx
f0100e46:	74 65                	je     f0100ead <page_alloc+0x76>

	struct PageInfo* pp;

	pp = page_free_list;

	page_free_list = page_free_list -> pp_link;
f0100e48:	8b 03                	mov    (%ebx),%eax
f0100e4a:	a3 40 85 11 f0       	mov    %eax,0xf0118540

	if(alloc_flags & ALLOC_ZERO){
f0100e4f:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e53:	74 58                	je     f0100ead <page_alloc+0x76>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e55:	89 d8                	mov    %ebx,%eax
f0100e57:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0100e5d:	c1 f8 03             	sar    $0x3,%eax
f0100e60:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e63:	89 c2                	mov    %eax,%edx
f0100e65:	c1 ea 0c             	shr    $0xc,%edx
f0100e68:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100e6e:	72 20                	jb     f0100e90 <page_alloc+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e70:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e74:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f0100e7b:	f0 
f0100e7c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100e83:	00 
f0100e84:	c7 04 24 e0 4b 10 f0 	movl   $0xf0104be0,(%esp)
f0100e8b:	e8 04 f2 ff ff       	call   f0100094 <_panic>
		memset(page2kva(pp), 0, PGSIZE);
f0100e90:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100e97:	00 
f0100e98:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100e9f:	00 
	return (void *)(pa + KERNBASE);
f0100ea0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ea5:	89 04 24             	mov    %eax,(%esp)
f0100ea8:	e8 56 2b 00 00       	call   f0103a03 <memset>
	}

	return pp;
}
f0100ead:	89 d8                	mov    %ebx,%eax
f0100eaf:	83 c4 14             	add    $0x14,%esp
f0100eb2:	5b                   	pop    %ebx
f0100eb3:	5d                   	pop    %ebp
f0100eb4:	c3                   	ret    

f0100eb5 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100eb5:	55                   	push   %ebp
f0100eb6:	89 e5                	mov    %esp,%ebp
f0100eb8:	83 ec 18             	sub    $0x18,%esp
f0100ebb:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.

	assert( pp->pp_ref==0 || pp->pp_link == NULL);
f0100ebe:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100ec3:	74 29                	je     f0100eee <page_free+0x39>
f0100ec5:	83 38 00             	cmpl   $0x0,(%eax)
f0100ec8:	74 24                	je     f0100eee <page_free+0x39>
f0100eca:	c7 44 24 0c 0c 45 10 	movl   $0xf010450c,0xc(%esp)
f0100ed1:	f0 
f0100ed2:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0100ed9:	f0 
f0100eda:	c7 44 24 04 52 01 00 	movl   $0x152,0x4(%esp)
f0100ee1:	00 
f0100ee2:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100ee9:	e8 a6 f1 ff ff       	call   f0100094 <_panic>

	pp->pp_link = page_free_list;
f0100eee:	8b 15 40 85 11 f0    	mov    0xf0118540,%edx
f0100ef4:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100ef6:	a3 40 85 11 f0       	mov    %eax,0xf0118540

}
f0100efb:	c9                   	leave  
f0100efc:	c3                   	ret    

f0100efd <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100efd:	55                   	push   %ebp
f0100efe:	89 e5                	mov    %esp,%ebp
f0100f00:	83 ec 18             	sub    $0x18,%esp
f0100f03:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f06:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100f0a:	83 ea 01             	sub    $0x1,%edx
f0100f0d:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f11:	66 85 d2             	test   %dx,%dx
f0100f14:	75 08                	jne    f0100f1e <page_decref+0x21>
		page_free(pp);
f0100f16:	89 04 24             	mov    %eax,(%esp)
f0100f19:	e8 97 ff ff ff       	call   f0100eb5 <page_free>
}
f0100f1e:	c9                   	leave  
f0100f1f:	c3                   	ret    

f0100f20 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f20:	55                   	push   %ebp
f0100f21:	89 e5                	mov    %esp,%ebp
f0100f23:	83 ec 28             	sub    $0x28,%esp
f0100f26:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100f29:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100f2c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100f2f:	8b 75 0c             	mov    0xc(%ebp),%esi
	pde_t *pde = NULL;
	pte_t *pte = NULL;

	struct PageInfo *pp;

	pde = pgdir+PDX(va);
f0100f32:	89 f3                	mov    %esi,%ebx
f0100f34:	c1 eb 16             	shr    $0x16,%ebx
f0100f37:	c1 e3 02             	shl    $0x2,%ebx
f0100f3a:	03 5d 08             	add    0x8(%ebp),%ebx

	if((*pde) & PTE_P){
f0100f3d:	8b 03                	mov    (%ebx),%eax
f0100f3f:	a8 01                	test   $0x1,%al
f0100f41:	74 3d                	je     f0100f80 <pgdir_walk+0x60>
		pte = KADDR(PTE_ADDR(*pde)) ;
f0100f43:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f48:	89 c2                	mov    %eax,%edx
f0100f4a:	c1 ea 0c             	shr    $0xc,%edx
f0100f4d:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100f53:	72 20                	jb     f0100f75 <pgdir_walk+0x55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f55:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f59:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f0100f60:	f0 
f0100f61:	c7 44 24 04 87 01 00 	movl   $0x187,0x4(%esp)
f0100f68:	00 
f0100f69:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100f70:	e8 1f f1 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100f75:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100f7b:	e9 97 00 00 00       	jmp    f0101017 <pgdir_walk+0xf7>
	}
	else{

		if(!create){
f0100f80:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f84:	0f 84 9b 00 00 00    	je     f0101025 <pgdir_walk+0x105>
			return NULL;
		}
		else if(!(pp=page_alloc(ALLOC_ZERO))){
f0100f8a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100f91:	e8 a1 fe ff ff       	call   f0100e37 <page_alloc>
f0100f96:	85 c0                	test   %eax,%eax
f0100f98:	0f 84 8e 00 00 00    	je     f010102c <pgdir_walk+0x10c>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f9e:	89 c1                	mov    %eax,%ecx
f0100fa0:	2b 0d 6c 89 11 f0    	sub    0xf011896c,%ecx
f0100fa6:	c1 f9 03             	sar    $0x3,%ecx
f0100fa9:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fac:	89 ca                	mov    %ecx,%edx
f0100fae:	c1 ea 0c             	shr    $0xc,%edx
f0100fb1:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100fb7:	72 20                	jb     f0100fd9 <pgdir_walk+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fb9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100fbd:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f0100fc4:	f0 
f0100fc5:	c7 44 24 04 91 01 00 	movl   $0x191,0x4(%esp)
f0100fcc:	00 
f0100fcd:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0100fd4:	e8 bb f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100fd9:	8d 91 00 00 00 f0    	lea    -0x10000000(%ecx),%edx
f0100fdf:	89 d7                	mov    %edx,%edi
			return NULL;		
		}
		else if(!(pte=(pte_t *)KADDR(page2pa(pp)))){
f0100fe1:	85 d2                	test   %edx,%edx
f0100fe3:	74 4e                	je     f0101033 <pgdir_walk+0x113>
			return NULL;	
		}

		pp->pp_ref++;
f0100fe5:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100fea:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100ff0:	77 20                	ja     f0101012 <pgdir_walk+0xf2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ff2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100ff6:	c7 44 24 08 34 45 10 	movl   $0xf0104534,0x8(%esp)
f0100ffd:	f0 
f0100ffe:	c7 44 24 04 96 01 00 	movl   $0x196,0x4(%esp)
f0101005:	00 
f0101006:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010100d:	e8 82 f0 ff ff       	call   f0100094 <_panic>
		*pde = PADDR(pte) | PTE_P | PTE_W | PTE_U;
f0101012:	83 c9 07             	or     $0x7,%ecx
f0101015:	89 0b                	mov    %ecx,(%ebx)
	}	

	return pte+PTX(va);
f0101017:	c1 ee 0a             	shr    $0xa,%esi
f010101a:	89 f0                	mov    %esi,%eax
f010101c:	25 fc 0f 00 00       	and    $0xffc,%eax
f0101021:	01 f8                	add    %edi,%eax
f0101023:	eb 13                	jmp    f0101038 <pgdir_walk+0x118>
		pte = KADDR(PTE_ADDR(*pde)) ;
	}
	else{

		if(!create){
			return NULL;
f0101025:	b8 00 00 00 00       	mov    $0x0,%eax
f010102a:	eb 0c                	jmp    f0101038 <pgdir_walk+0x118>
		}
		else if(!(pp=page_alloc(ALLOC_ZERO))){
			return NULL;		
f010102c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101031:	eb 05                	jmp    f0101038 <pgdir_walk+0x118>
		}
		else if(!(pte=(pte_t *)KADDR(page2pa(pp)))){
			return NULL;	
f0101033:	b8 00 00 00 00       	mov    $0x0,%eax
		pp->pp_ref++;
		*pde = PADDR(pte) | PTE_P | PTE_W | PTE_U;
	}	

	return pte+PTX(va);
}
f0101038:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010103b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010103e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101041:	89 ec                	mov    %ebp,%esp
f0101043:	5d                   	pop    %ebp
f0101044:	c3                   	ret    

f0101045 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101045:	55                   	push   %ebp
f0101046:	89 e5                	mov    %esp,%ebp
f0101048:	57                   	push   %edi
f0101049:	56                   	push   %esi
f010104a:	53                   	push   %ebx
f010104b:	83 ec 2c             	sub    $0x2c,%esp
f010104e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101051:	89 d6                	mov    %edx,%esi
f0101053:	89 cb                	mov    %ecx,%ebx
	physaddr_t pa_ = pa;
	pte_t *pte=NULL;

	ROUNDUP(size,PGSIZE);
	
	assert(size % PGSIZE == 0 || cprintf("size : %x \n", size));
f0101055:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f010105b:	74 14                	je     f0101071 <boot_map_region+0x2c>
f010105d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101061:	c7 04 24 8a 4c 10 f0 	movl   $0xf0104c8a,(%esp)
f0101068:	e8 6d 1e 00 00       	call   f0102eda <cprintf>
f010106d:	85 c0                	test   %eax,%eax
f010106f:	74 1b                	je     f010108c <boot_map_region+0x47>

	int i;

	for(i=0; i<size/PGSIZE; i++){
f0101071:	c1 eb 0c             	shr    $0xc,%ebx
f0101074:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101077:	8b 7d 08             	mov    0x8(%ebp),%edi
f010107a:	89 f3                	mov    %esi,%ebx
f010107c:	be 00 00 00 00       	mov    $0x0,%esi
	for(i=0; i<size/PGSIZE; i++){
		pte = pgdir_walk(pgdir, (const void *)va_, 1);

		if(!pte) return;

		*pte= PTE_ADDR(pa_) | perm | PTE_P;
f0101081:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101084:	83 c8 01             	or     $0x1,%eax
f0101087:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010108a:	eb 5b                	jmp    f01010e7 <boot_map_region+0xa2>
	physaddr_t pa_ = pa;
	pte_t *pte=NULL;

	ROUNDUP(size,PGSIZE);
	
	assert(size % PGSIZE == 0 || cprintf("size : %x \n", size));
f010108c:	c7 44 24 0c 58 45 10 	movl   $0xf0104558,0xc(%esp)
f0101093:	f0 
f0101094:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010109b:	f0 
f010109c:	c7 44 24 04 b2 01 00 	movl   $0x1b2,0x4(%esp)
f01010a3:	00 
f01010a4:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01010ab:	e8 e4 ef ff ff       	call   f0100094 <_panic>

	int i;

	for(i=0; i<size/PGSIZE; i++){
		pte = pgdir_walk(pgdir, (const void *)va_, 1);
f01010b0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01010b7:	00 
f01010b8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010bc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010bf:	89 04 24             	mov    %eax,(%esp)
f01010c2:	e8 59 fe ff ff       	call   f0100f20 <pgdir_walk>

		if(!pte) return;
f01010c7:	85 c0                	test   %eax,%eax
f01010c9:	74 21                	je     f01010ec <boot_map_region+0xa7>

		*pte= PTE_ADDR(pa_) | perm | PTE_P;
f01010cb:	89 fa                	mov    %edi,%edx
f01010cd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01010d3:	0b 55 dc             	or     -0x24(%ebp),%edx
f01010d6:	89 10                	mov    %edx,(%eax)

		va_ += PGSIZE;
f01010d8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		pa_ += PGSIZE;
f01010de:	81 c7 00 10 00 00    	add    $0x1000,%edi
	
	assert(size % PGSIZE == 0 || cprintf("size : %x \n", size));

	int i;

	for(i=0; i<size/PGSIZE; i++){
f01010e4:	83 c6 01             	add    $0x1,%esi
f01010e7:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01010ea:	75 c4                	jne    f01010b0 <boot_map_region+0x6b>
		*pte= PTE_ADDR(pa_) | perm | PTE_P;

		va_ += PGSIZE;
		pa_ += PGSIZE;
	} 
}
f01010ec:	83 c4 2c             	add    $0x2c,%esp
f01010ef:	5b                   	pop    %ebx
f01010f0:	5e                   	pop    %esi
f01010f1:	5f                   	pop    %edi
f01010f2:	5d                   	pop    %ebp
f01010f3:	c3                   	ret    

f01010f4 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010f4:	55                   	push   %ebp
f01010f5:	89 e5                	mov    %esp,%ebp
f01010f7:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir,va,0);
f01010fa:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101101:	00 
f0101102:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101105:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101109:	8b 45 08             	mov    0x8(%ebp),%eax
f010110c:	89 04 24             	mov    %eax,(%esp)
f010110f:	e8 0c fe ff ff       	call   f0100f20 <pgdir_walk>

	if(!pte) return NULL;
f0101114:	85 c0                	test   %eax,%eax
f0101116:	74 39                	je     f0101151 <page_lookup+0x5d>

	*pte_store = pte;
f0101118:	8b 55 10             	mov    0x10(%ebp),%edx
f010111b:	89 02                	mov    %eax,(%edx)
	
	return pa2page(PTE_ADDR(*pte));
f010111d:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010111f:	c1 e8 0c             	shr    $0xc,%eax
f0101122:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f0101128:	72 1c                	jb     f0101146 <page_lookup+0x52>
		panic("pa2page called with invalid pa");
f010112a:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f0101131:	f0 
f0101132:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101139:	00 
f010113a:	c7 04 24 e0 4b 10 f0 	movl   $0xf0104be0,(%esp)
f0101141:	e8 4e ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101146:	c1 e0 03             	shl    $0x3,%eax
f0101149:	03 05 6c 89 11 f0    	add    0xf011896c,%eax
f010114f:	eb 05                	jmp    f0101156 <page_lookup+0x62>
{
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir,va,0);

	if(!pte) return NULL;
f0101151:	b8 00 00 00 00       	mov    $0x0,%eax

	*pte_store = pte;
	
	return pa2page(PTE_ADDR(*pte));
}
f0101156:	c9                   	leave  
f0101157:	c3                   	ret    

f0101158 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101158:	55                   	push   %ebp
f0101159:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010115b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010115e:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101161:	5d                   	pop    %ebp
f0101162:	c3                   	ret    

f0101163 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101163:	55                   	push   %ebp
f0101164:	89 e5                	mov    %esp,%ebp
f0101166:	56                   	push   %esi
f0101167:	53                   	push   %ebx
f0101168:	83 ec 20             	sub    $0x20,%esp
f010116b:	8b 75 08             	mov    0x8(%ebp),%esi
f010116e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101171:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101178:	00 
f0101179:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010117d:	89 34 24             	mov    %esi,(%esp)
f0101180:	e8 9b fd ff ff       	call   f0100f20 <pgdir_walk>
f0101185:	89 45 f4             	mov    %eax,-0xc(%ebp)

	pte_t **pte_store=&pte;
f0101188:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010118b:	89 44 24 08          	mov    %eax,0x8(%esp)

	struct PageInfo *pp = page_lookup(pgdir,va,pte_store);
f010118f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101193:	89 34 24             	mov    %esi,(%esp)
f0101196:	e8 59 ff ff ff       	call   f01010f4 <page_lookup>

	if(!pp){return;}
f010119b:	85 c0                	test   %eax,%eax
f010119d:	74 1d                	je     f01011bc <page_remove+0x59>

	page_decref(pp);
f010119f:	89 04 24             	mov    %eax,(%esp)
f01011a2:	e8 56 fd ff ff       	call   f0100efd <page_decref>

	**pte_store = 0;
f01011a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011aa:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    tlb_invalidate(pgdir,va);  
f01011b0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011b4:	89 34 24             	mov    %esi,(%esp)
f01011b7:	e8 9c ff ff ff       	call   f0101158 <tlb_invalidate>
}
f01011bc:	83 c4 20             	add    $0x20,%esp
f01011bf:	5b                   	pop    %ebx
f01011c0:	5e                   	pop    %esi
f01011c1:	5d                   	pop    %ebp
f01011c2:	c3                   	ret    

f01011c3 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01011c3:	55                   	push   %ebp
f01011c4:	89 e5                	mov    %esp,%ebp
f01011c6:	83 ec 28             	sub    $0x28,%esp
f01011c9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01011cc:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01011cf:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01011d2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01011d5:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir,va,0);
f01011d8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01011df:	00 
f01011e0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01011e7:	89 04 24             	mov    %eax,(%esp)
f01011ea:	e8 31 fd ff ff       	call   f0100f20 <pgdir_walk>
f01011ef:	89 c3                	mov    %eax,%ebx

	physaddr_t pa = page2pa(pp);

	if(pte){
f01011f1:	85 c0                	test   %eax,%eax
f01011f3:	74 26                	je     f010121b <page_insert+0x58>
		if(*pte & PTE_P) page_remove(pgdir,va);
f01011f5:	f6 00 01             	testb  $0x1,(%eax)
f01011f8:	74 0f                	je     f0101209 <page_insert+0x46>
f01011fa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101201:	89 04 24             	mov    %eax,(%esp)
f0101204:	e8 5a ff ff ff       	call   f0101163 <page_remove>
		if(page_free_list == pp) page_free_list=page_free_list->pp_link;
f0101209:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f010120e:	39 f0                	cmp    %esi,%eax
f0101210:	75 26                	jne    f0101238 <page_insert+0x75>
f0101212:	8b 00                	mov    (%eax),%eax
f0101214:	a3 40 85 11 f0       	mov    %eax,0xf0118540
f0101219:	eb 1d                	jmp    f0101238 <page_insert+0x75>
	}
	else{
		pte = pgdir_walk(pgdir,va,1);
f010121b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101222:	00 
f0101223:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101227:	8b 45 08             	mov    0x8(%ebp),%eax
f010122a:	89 04 24             	mov    %eax,(%esp)
f010122d:	e8 ee fc ff ff       	call   f0100f20 <pgdir_walk>
f0101232:	89 c3                	mov    %eax,%ebx
		if(!pte) return -E_NO_MEM;
f0101234:	85 c0                	test   %eax,%eax
f0101236:	74 33                	je     f010126b <page_insert+0xa8>
	}

	*pte = page2pa(pp) | perm | PTE_P;
f0101238:	8b 45 14             	mov    0x14(%ebp),%eax
f010123b:	83 c8 01             	or     $0x1,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010123e:	89 f2                	mov    %esi,%edx
f0101240:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101246:	c1 fa 03             	sar    $0x3,%edx
f0101249:	c1 e2 0c             	shl    $0xc,%edx
f010124c:	09 d0                	or     %edx,%eax
f010124e:	89 03                	mov    %eax,(%ebx)

	pp->pp_ref++;
f0101250:	66 83 46 04 01       	addw   $0x1,0x4(%esi)

	tlb_invalidate(pgdir,va);
f0101255:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101259:	8b 45 08             	mov    0x8(%ebp),%eax
f010125c:	89 04 24             	mov    %eax,(%esp)
f010125f:	e8 f4 fe ff ff       	call   f0101158 <tlb_invalidate>

	return 0;
f0101264:	b8 00 00 00 00       	mov    $0x0,%eax
f0101269:	eb 05                	jmp    f0101270 <page_insert+0xad>
		if(*pte & PTE_P) page_remove(pgdir,va);
		if(page_free_list == pp) page_free_list=page_free_list->pp_link;
	}
	else{
		pte = pgdir_walk(pgdir,va,1);
		if(!pte) return -E_NO_MEM;
f010126b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	pp->pp_ref++;

	tlb_invalidate(pgdir,va);

	return 0;
}
f0101270:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101273:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101276:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101279:	89 ec                	mov    %ebp,%esp
f010127b:	5d                   	pop    %ebp
f010127c:	c3                   	ret    

f010127d <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010127d:	55                   	push   %ebp
f010127e:	89 e5                	mov    %esp,%ebp
f0101280:	57                   	push   %edi
f0101281:	56                   	push   %esi
f0101282:	53                   	push   %ebx
f0101283:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101286:	b8 15 00 00 00       	mov    $0x15,%eax
f010128b:	e8 7d f7 ff ff       	call   f0100a0d <nvram_read>
f0101290:	c1 e0 0a             	shl    $0xa,%eax
f0101293:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101299:	85 c0                	test   %eax,%eax
f010129b:	0f 48 c2             	cmovs  %edx,%eax
f010129e:	c1 f8 0c             	sar    $0xc,%eax
f01012a1:	a3 38 85 11 f0       	mov    %eax,0xf0118538
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01012a6:	b8 17 00 00 00       	mov    $0x17,%eax
f01012ab:	e8 5d f7 ff ff       	call   f0100a0d <nvram_read>
f01012b0:	c1 e0 0a             	shl    $0xa,%eax
f01012b3:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01012b9:	85 c0                	test   %eax,%eax
f01012bb:	0f 48 c2             	cmovs  %edx,%eax
f01012be:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01012c1:	85 c0                	test   %eax,%eax
f01012c3:	74 0e                	je     f01012d3 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012c5:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01012cb:	89 15 64 89 11 f0    	mov    %edx,0xf0118964
f01012d1:	eb 0c                	jmp    f01012df <mem_init+0x62>
	else
		npages = npages_basemem;
f01012d3:	8b 15 38 85 11 f0    	mov    0xf0118538,%edx
f01012d9:	89 15 64 89 11 f0    	mov    %edx,0xf0118964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01012df:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012e2:	c1 e8 0a             	shr    $0xa,%eax
f01012e5:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01012e9:	a1 38 85 11 f0       	mov    0xf0118538,%eax
f01012ee:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012f1:	c1 e8 0a             	shr    $0xa,%eax
f01012f4:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01012f8:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f01012fd:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101300:	c1 e8 0a             	shr    $0xa,%eax
f0101303:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101307:	c7 04 24 ac 45 10 f0 	movl   $0xf01045ac,(%esp)
f010130e:	e8 c7 1b 00 00       	call   f0102eda <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101313:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101318:	e8 47 f6 ff ff       	call   f0100964 <boot_alloc>
f010131d:	a3 68 89 11 f0       	mov    %eax,0xf0118968
	memset(kern_pgdir, 0, PGSIZE);
f0101322:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101329:	00 
f010132a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101331:	00 
f0101332:	89 04 24             	mov    %eax,(%esp)
f0101335:	e8 c9 26 00 00       	call   f0103a03 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010133a:	a1 68 89 11 f0       	mov    0xf0118968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010133f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101344:	77 20                	ja     f0101366 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101346:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010134a:	c7 44 24 08 34 45 10 	movl   $0xf0104534,0x8(%esp)
f0101351:	f0 
f0101352:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
f0101359:	00 
f010135a:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101361:	e8 2e ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101366:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010136c:	83 ca 05             	or     $0x5,%edx
f010136f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f0101375:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f010137a:	c1 e0 03             	shl    $0x3,%eax
f010137d:	e8 e2 f5 ff ff       	call   f0100964 <boot_alloc>
f0101382:	a3 6c 89 11 f0       	mov    %eax,0xf011896c

	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101387:	8b 15 64 89 11 f0    	mov    0xf0118964,%edx
f010138d:	c1 e2 03             	shl    $0x3,%edx
f0101390:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101394:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010139b:	00 
f010139c:	89 04 24             	mov    %eax,(%esp)
f010139f:	e8 5f 26 00 00       	call   f0103a03 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01013a4:	e8 be f9 ff ff       	call   f0100d67 <page_init>

	check_page_free_list(1);
f01013a9:	b8 01 00 00 00       	mov    $0x1,%eax
f01013ae:	e8 8c f6 ff ff       	call   f0100a3f <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01013b3:	83 3d 6c 89 11 f0 00 	cmpl   $0x0,0xf011896c
f01013ba:	75 1c                	jne    f01013d8 <mem_init+0x15b>
		panic("'pages' is a null pointer!");
f01013bc:	c7 44 24 08 96 4c 10 	movl   $0xf0104c96,0x8(%esp)
f01013c3:	f0 
f01013c4:	c7 44 24 04 8c 02 00 	movl   $0x28c,0x4(%esp)
f01013cb:	00 
f01013cc:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01013d3:	e8 bc ec ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013d8:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f01013dd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013e2:	eb 05                	jmp    f01013e9 <mem_init+0x16c>
		++nfree;
f01013e4:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013e7:	8b 00                	mov    (%eax),%eax
f01013e9:	85 c0                	test   %eax,%eax
f01013eb:	75 f7                	jne    f01013e4 <mem_init+0x167>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013ed:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013f4:	e8 3e fa ff ff       	call   f0100e37 <page_alloc>
f01013f9:	89 c6                	mov    %eax,%esi
f01013fb:	85 c0                	test   %eax,%eax
f01013fd:	75 24                	jne    f0101423 <mem_init+0x1a6>
f01013ff:	c7 44 24 0c b1 4c 10 	movl   $0xf0104cb1,0xc(%esp)
f0101406:	f0 
f0101407:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010140e:	f0 
f010140f:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f0101416:	00 
f0101417:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010141e:	e8 71 ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101423:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010142a:	e8 08 fa ff ff       	call   f0100e37 <page_alloc>
f010142f:	89 c7                	mov    %eax,%edi
f0101431:	85 c0                	test   %eax,%eax
f0101433:	75 24                	jne    f0101459 <mem_init+0x1dc>
f0101435:	c7 44 24 0c c7 4c 10 	movl   $0xf0104cc7,0xc(%esp)
f010143c:	f0 
f010143d:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101444:	f0 
f0101445:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
f010144c:	00 
f010144d:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101454:	e8 3b ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101459:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101460:	e8 d2 f9 ff ff       	call   f0100e37 <page_alloc>
f0101465:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101468:	85 c0                	test   %eax,%eax
f010146a:	75 24                	jne    f0101490 <mem_init+0x213>
f010146c:	c7 44 24 0c dd 4c 10 	movl   $0xf0104cdd,0xc(%esp)
f0101473:	f0 
f0101474:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010147b:	f0 
f010147c:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f0101483:	00 
f0101484:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010148b:	e8 04 ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101490:	39 fe                	cmp    %edi,%esi
f0101492:	75 24                	jne    f01014b8 <mem_init+0x23b>
f0101494:	c7 44 24 0c f3 4c 10 	movl   $0xf0104cf3,0xc(%esp)
f010149b:	f0 
f010149c:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01014a3:	f0 
f01014a4:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f01014ab:	00 
f01014ac:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01014b3:	e8 dc eb ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014b8:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01014bb:	74 05                	je     f01014c2 <mem_init+0x245>
f01014bd:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01014c0:	75 24                	jne    f01014e6 <mem_init+0x269>
f01014c2:	c7 44 24 0c e8 45 10 	movl   $0xf01045e8,0xc(%esp)
f01014c9:	f0 
f01014ca:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01014d1:	f0 
f01014d2:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f01014d9:	00 
f01014da:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01014e1:	e8 ae eb ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014e6:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014ec:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f01014f1:	c1 e0 0c             	shl    $0xc,%eax
f01014f4:	89 f1                	mov    %esi,%ecx
f01014f6:	29 d1                	sub    %edx,%ecx
f01014f8:	c1 f9 03             	sar    $0x3,%ecx
f01014fb:	c1 e1 0c             	shl    $0xc,%ecx
f01014fe:	39 c1                	cmp    %eax,%ecx
f0101500:	72 24                	jb     f0101526 <mem_init+0x2a9>
f0101502:	c7 44 24 0c 05 4d 10 	movl   $0xf0104d05,0xc(%esp)
f0101509:	f0 
f010150a:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101511:	f0 
f0101512:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f0101519:	00 
f010151a:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101521:	e8 6e eb ff ff       	call   f0100094 <_panic>
f0101526:	89 f9                	mov    %edi,%ecx
f0101528:	29 d1                	sub    %edx,%ecx
f010152a:	c1 f9 03             	sar    $0x3,%ecx
f010152d:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101530:	39 c8                	cmp    %ecx,%eax
f0101532:	77 24                	ja     f0101558 <mem_init+0x2db>
f0101534:	c7 44 24 0c 22 4d 10 	movl   $0xf0104d22,0xc(%esp)
f010153b:	f0 
f010153c:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101543:	f0 
f0101544:	c7 44 24 04 9c 02 00 	movl   $0x29c,0x4(%esp)
f010154b:	00 
f010154c:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101553:	e8 3c eb ff ff       	call   f0100094 <_panic>
f0101558:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010155b:	29 d1                	sub    %edx,%ecx
f010155d:	89 ca                	mov    %ecx,%edx
f010155f:	c1 fa 03             	sar    $0x3,%edx
f0101562:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101565:	39 d0                	cmp    %edx,%eax
f0101567:	77 24                	ja     f010158d <mem_init+0x310>
f0101569:	c7 44 24 0c 3f 4d 10 	movl   $0xf0104d3f,0xc(%esp)
f0101570:	f0 
f0101571:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101578:	f0 
f0101579:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
f0101580:	00 
f0101581:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101588:	e8 07 eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010158d:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f0101592:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101595:	c7 05 40 85 11 f0 00 	movl   $0x0,0xf0118540
f010159c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010159f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015a6:	e8 8c f8 ff ff       	call   f0100e37 <page_alloc>
f01015ab:	85 c0                	test   %eax,%eax
f01015ad:	74 24                	je     f01015d3 <mem_init+0x356>
f01015af:	c7 44 24 0c 5c 4d 10 	movl   $0xf0104d5c,0xc(%esp)
f01015b6:	f0 
f01015b7:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01015be:	f0 
f01015bf:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
f01015c6:	00 
f01015c7:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01015ce:	e8 c1 ea ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01015d3:	89 34 24             	mov    %esi,(%esp)
f01015d6:	e8 da f8 ff ff       	call   f0100eb5 <page_free>
	page_free(pp1);
f01015db:	89 3c 24             	mov    %edi,(%esp)
f01015de:	e8 d2 f8 ff ff       	call   f0100eb5 <page_free>
	page_free(pp2);
f01015e3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015e6:	89 04 24             	mov    %eax,(%esp)
f01015e9:	e8 c7 f8 ff ff       	call   f0100eb5 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015f5:	e8 3d f8 ff ff       	call   f0100e37 <page_alloc>
f01015fa:	89 c6                	mov    %eax,%esi
f01015fc:	85 c0                	test   %eax,%eax
f01015fe:	75 24                	jne    f0101624 <mem_init+0x3a7>
f0101600:	c7 44 24 0c b1 4c 10 	movl   $0xf0104cb1,0xc(%esp)
f0101607:	f0 
f0101608:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010160f:	f0 
f0101610:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f0101617:	00 
f0101618:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010161f:	e8 70 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101624:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010162b:	e8 07 f8 ff ff       	call   f0100e37 <page_alloc>
f0101630:	89 c7                	mov    %eax,%edi
f0101632:	85 c0                	test   %eax,%eax
f0101634:	75 24                	jne    f010165a <mem_init+0x3dd>
f0101636:	c7 44 24 0c c7 4c 10 	movl   $0xf0104cc7,0xc(%esp)
f010163d:	f0 
f010163e:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101645:	f0 
f0101646:	c7 44 24 04 ac 02 00 	movl   $0x2ac,0x4(%esp)
f010164d:	00 
f010164e:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101655:	e8 3a ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010165a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101661:	e8 d1 f7 ff ff       	call   f0100e37 <page_alloc>
f0101666:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101669:	85 c0                	test   %eax,%eax
f010166b:	75 24                	jne    f0101691 <mem_init+0x414>
f010166d:	c7 44 24 0c dd 4c 10 	movl   $0xf0104cdd,0xc(%esp)
f0101674:	f0 
f0101675:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010167c:	f0 
f010167d:	c7 44 24 04 ad 02 00 	movl   $0x2ad,0x4(%esp)
f0101684:	00 
f0101685:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010168c:	e8 03 ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101691:	39 fe                	cmp    %edi,%esi
f0101693:	75 24                	jne    f01016b9 <mem_init+0x43c>
f0101695:	c7 44 24 0c f3 4c 10 	movl   $0xf0104cf3,0xc(%esp)
f010169c:	f0 
f010169d:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01016a4:	f0 
f01016a5:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f01016ac:	00 
f01016ad:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01016b4:	e8 db e9 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016b9:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01016bc:	74 05                	je     f01016c3 <mem_init+0x446>
f01016be:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01016c1:	75 24                	jne    f01016e7 <mem_init+0x46a>
f01016c3:	c7 44 24 0c e8 45 10 	movl   $0xf01045e8,0xc(%esp)
f01016ca:	f0 
f01016cb:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01016d2:	f0 
f01016d3:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f01016da:	00 
f01016db:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01016e2:	e8 ad e9 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f01016e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016ee:	e8 44 f7 ff ff       	call   f0100e37 <page_alloc>
f01016f3:	85 c0                	test   %eax,%eax
f01016f5:	74 24                	je     f010171b <mem_init+0x49e>
f01016f7:	c7 44 24 0c 5c 4d 10 	movl   $0xf0104d5c,0xc(%esp)
f01016fe:	f0 
f01016ff:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101706:	f0 
f0101707:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
f010170e:	00 
f010170f:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101716:	e8 79 e9 ff ff       	call   f0100094 <_panic>
f010171b:	89 f0                	mov    %esi,%eax
f010171d:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0101723:	c1 f8 03             	sar    $0x3,%eax
f0101726:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101729:	89 c2                	mov    %eax,%edx
f010172b:	c1 ea 0c             	shr    $0xc,%edx
f010172e:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0101734:	72 20                	jb     f0101756 <mem_init+0x4d9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101736:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010173a:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f0101741:	f0 
f0101742:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101749:	00 
f010174a:	c7 04 24 e0 4b 10 f0 	movl   $0xf0104be0,(%esp)
f0101751:	e8 3e e9 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101756:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010175d:	00 
f010175e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101765:	00 
	return (void *)(pa + KERNBASE);
f0101766:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010176b:	89 04 24             	mov    %eax,(%esp)
f010176e:	e8 90 22 00 00       	call   f0103a03 <memset>
	page_free(pp0);
f0101773:	89 34 24             	mov    %esi,(%esp)
f0101776:	e8 3a f7 ff ff       	call   f0100eb5 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010177b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101782:	e8 b0 f6 ff ff       	call   f0100e37 <page_alloc>
f0101787:	85 c0                	test   %eax,%eax
f0101789:	75 24                	jne    f01017af <mem_init+0x532>
f010178b:	c7 44 24 0c 6b 4d 10 	movl   $0xf0104d6b,0xc(%esp)
f0101792:	f0 
f0101793:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010179a:	f0 
f010179b:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f01017a2:	00 
f01017a3:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01017aa:	e8 e5 e8 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f01017af:	39 c6                	cmp    %eax,%esi
f01017b1:	74 24                	je     f01017d7 <mem_init+0x55a>
f01017b3:	c7 44 24 0c 89 4d 10 	movl   $0xf0104d89,0xc(%esp)
f01017ba:	f0 
f01017bb:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01017c2:	f0 
f01017c3:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f01017ca:	00 
f01017cb:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01017d2:	e8 bd e8 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017d7:	89 f2                	mov    %esi,%edx
f01017d9:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f01017df:	c1 fa 03             	sar    $0x3,%edx
f01017e2:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017e5:	89 d0                	mov    %edx,%eax
f01017e7:	c1 e8 0c             	shr    $0xc,%eax
f01017ea:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f01017f0:	72 20                	jb     f0101812 <mem_init+0x595>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017f2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01017f6:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f01017fd:	f0 
f01017fe:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101805:	00 
f0101806:	c7 04 24 e0 4b 10 f0 	movl   $0xf0104be0,(%esp)
f010180d:	e8 82 e8 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101812:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101818:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010181e:	80 38 00             	cmpb   $0x0,(%eax)
f0101821:	74 24                	je     f0101847 <mem_init+0x5ca>
f0101823:	c7 44 24 0c 99 4d 10 	movl   $0xf0104d99,0xc(%esp)
f010182a:	f0 
f010182b:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101832:	f0 
f0101833:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f010183a:	00 
f010183b:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101842:	e8 4d e8 ff ff       	call   f0100094 <_panic>
f0101847:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010184a:	39 d0                	cmp    %edx,%eax
f010184c:	75 d0                	jne    f010181e <mem_init+0x5a1>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010184e:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101851:	89 15 40 85 11 f0    	mov    %edx,0xf0118540

	// free the pages we took
	page_free(pp0);
f0101857:	89 34 24             	mov    %esi,(%esp)
f010185a:	e8 56 f6 ff ff       	call   f0100eb5 <page_free>
	page_free(pp1);
f010185f:	89 3c 24             	mov    %edi,(%esp)
f0101862:	e8 4e f6 ff ff       	call   f0100eb5 <page_free>
	page_free(pp2);
f0101867:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010186a:	89 04 24             	mov    %eax,(%esp)
f010186d:	e8 43 f6 ff ff       	call   f0100eb5 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101872:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f0101877:	eb 05                	jmp    f010187e <mem_init+0x601>
		--nfree;
f0101879:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010187c:	8b 00                	mov    (%eax),%eax
f010187e:	85 c0                	test   %eax,%eax
f0101880:	75 f7                	jne    f0101879 <mem_init+0x5fc>
		--nfree;
	assert(nfree == 0);
f0101882:	85 db                	test   %ebx,%ebx
f0101884:	74 24                	je     f01018aa <mem_init+0x62d>
f0101886:	c7 44 24 0c a3 4d 10 	movl   $0xf0104da3,0xc(%esp)
f010188d:	f0 
f010188e:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101895:	f0 
f0101896:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f010189d:	00 
f010189e:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01018a5:	e8 ea e7 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01018aa:	c7 04 24 08 46 10 f0 	movl   $0xf0104608,(%esp)
f01018b1:	e8 24 16 00 00       	call   f0102eda <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018b6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018bd:	e8 75 f5 ff ff       	call   f0100e37 <page_alloc>
f01018c2:	89 c7                	mov    %eax,%edi
f01018c4:	85 c0                	test   %eax,%eax
f01018c6:	75 24                	jne    f01018ec <mem_init+0x66f>
f01018c8:	c7 44 24 0c b1 4c 10 	movl   $0xf0104cb1,0xc(%esp)
f01018cf:	f0 
f01018d0:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01018d7:	f0 
f01018d8:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f01018df:	00 
f01018e0:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01018e7:	e8 a8 e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01018ec:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018f3:	e8 3f f5 ff ff       	call   f0100e37 <page_alloc>
f01018f8:	89 c6                	mov    %eax,%esi
f01018fa:	85 c0                	test   %eax,%eax
f01018fc:	75 24                	jne    f0101922 <mem_init+0x6a5>
f01018fe:	c7 44 24 0c c7 4c 10 	movl   $0xf0104cc7,0xc(%esp)
f0101905:	f0 
f0101906:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010190d:	f0 
f010190e:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0101915:	00 
f0101916:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010191d:	e8 72 e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101922:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101929:	e8 09 f5 ff ff       	call   f0100e37 <page_alloc>
f010192e:	89 c3                	mov    %eax,%ebx
f0101930:	85 c0                	test   %eax,%eax
f0101932:	75 24                	jne    f0101958 <mem_init+0x6db>
f0101934:	c7 44 24 0c dd 4c 10 	movl   $0xf0104cdd,0xc(%esp)
f010193b:	f0 
f010193c:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101943:	f0 
f0101944:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f010194b:	00 
f010194c:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101953:	e8 3c e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101958:	39 f7                	cmp    %esi,%edi
f010195a:	75 24                	jne    f0101980 <mem_init+0x703>
f010195c:	c7 44 24 0c f3 4c 10 	movl   $0xf0104cf3,0xc(%esp)
f0101963:	f0 
f0101964:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010196b:	f0 
f010196c:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101973:	00 
f0101974:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010197b:	e8 14 e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101980:	39 c6                	cmp    %eax,%esi
f0101982:	74 04                	je     f0101988 <mem_init+0x70b>
f0101984:	39 c7                	cmp    %eax,%edi
f0101986:	75 24                	jne    f01019ac <mem_init+0x72f>
f0101988:	c7 44 24 0c e8 45 10 	movl   $0xf01045e8,0xc(%esp)
f010198f:	f0 
f0101990:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101997:	f0 
f0101998:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f010199f:	00 
f01019a0:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01019a7:	e8 e8 e6 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019ac:	8b 15 40 85 11 f0    	mov    0xf0118540,%edx
f01019b2:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f01019b5:	c7 05 40 85 11 f0 00 	movl   $0x0,0xf0118540
f01019bc:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019bf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019c6:	e8 6c f4 ff ff       	call   f0100e37 <page_alloc>
f01019cb:	85 c0                	test   %eax,%eax
f01019cd:	74 24                	je     f01019f3 <mem_init+0x776>
f01019cf:	c7 44 24 0c 5c 4d 10 	movl   $0xf0104d5c,0xc(%esp)
f01019d6:	f0 
f01019d7:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01019de:	f0 
f01019df:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f01019e6:	00 
f01019e7:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01019ee:	e8 a1 e6 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019f3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019f6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019fa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101a01:	00 
f0101a02:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101a07:	89 04 24             	mov    %eax,(%esp)
f0101a0a:	e8 e5 f6 ff ff       	call   f01010f4 <page_lookup>
f0101a0f:	85 c0                	test   %eax,%eax
f0101a11:	74 24                	je     f0101a37 <mem_init+0x7ba>
f0101a13:	c7 44 24 0c 28 46 10 	movl   $0xf0104628,0xc(%esp)
f0101a1a:	f0 
f0101a1b:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101a22:	f0 
f0101a23:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101a2a:	00 
f0101a2b:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101a32:	e8 5d e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a37:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a3e:	00 
f0101a3f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a46:	00 
f0101a47:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101a4b:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101a50:	89 04 24             	mov    %eax,(%esp)
f0101a53:	e8 6b f7 ff ff       	call   f01011c3 <page_insert>
f0101a58:	85 c0                	test   %eax,%eax
f0101a5a:	78 24                	js     f0101a80 <mem_init+0x803>
f0101a5c:	c7 44 24 0c 60 46 10 	movl   $0xf0104660,0xc(%esp)
f0101a63:	f0 
f0101a64:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101a6b:	f0 
f0101a6c:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0101a73:	00 
f0101a74:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101a7b:	e8 14 e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a80:	89 3c 24             	mov    %edi,(%esp)
f0101a83:	e8 2d f4 ff ff       	call   f0100eb5 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a88:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a8f:	00 
f0101a90:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a97:	00 
f0101a98:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101a9c:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101aa1:	89 04 24             	mov    %eax,(%esp)
f0101aa4:	e8 1a f7 ff ff       	call   f01011c3 <page_insert>
f0101aa9:	85 c0                	test   %eax,%eax
f0101aab:	74 24                	je     f0101ad1 <mem_init+0x854>
f0101aad:	c7 44 24 0c 90 46 10 	movl   $0xf0104690,0xc(%esp)
f0101ab4:	f0 
f0101ab5:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101abc:	f0 
f0101abd:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0101ac4:	00 
f0101ac5:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101acc:	e8 c3 e5 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ad1:	8b 0d 68 89 11 f0    	mov    0xf0118968,%ecx
f0101ad7:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ada:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0101adf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ae2:	8b 11                	mov    (%ecx),%edx
f0101ae4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101aea:	89 f8                	mov    %edi,%eax
f0101aec:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101aef:	c1 f8 03             	sar    $0x3,%eax
f0101af2:	c1 e0 0c             	shl    $0xc,%eax
f0101af5:	39 c2                	cmp    %eax,%edx
f0101af7:	74 24                	je     f0101b1d <mem_init+0x8a0>
f0101af9:	c7 44 24 0c c0 46 10 	movl   $0xf01046c0,0xc(%esp)
f0101b00:	f0 
f0101b01:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101b08:	f0 
f0101b09:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0101b10:	00 
f0101b11:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101b18:	e8 77 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b1d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b22:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b25:	e8 72 ee ff ff       	call   f010099c <check_va2pa>
f0101b2a:	89 f2                	mov    %esi,%edx
f0101b2c:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101b2f:	c1 fa 03             	sar    $0x3,%edx
f0101b32:	c1 e2 0c             	shl    $0xc,%edx
f0101b35:	39 d0                	cmp    %edx,%eax
f0101b37:	74 24                	je     f0101b5d <mem_init+0x8e0>
f0101b39:	c7 44 24 0c e8 46 10 	movl   $0xf01046e8,0xc(%esp)
f0101b40:	f0 
f0101b41:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101b48:	f0 
f0101b49:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0101b50:	00 
f0101b51:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101b58:	e8 37 e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101b5d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b62:	74 24                	je     f0101b88 <mem_init+0x90b>
f0101b64:	c7 44 24 0c ae 4d 10 	movl   $0xf0104dae,0xc(%esp)
f0101b6b:	f0 
f0101b6c:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101b73:	f0 
f0101b74:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0101b7b:	00 
f0101b7c:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101b83:	e8 0c e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101b88:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b8d:	74 24                	je     f0101bb3 <mem_init+0x936>
f0101b8f:	c7 44 24 0c bf 4d 10 	movl   $0xf0104dbf,0xc(%esp)
f0101b96:	f0 
f0101b97:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101b9e:	f0 
f0101b9f:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0101ba6:	00 
f0101ba7:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101bae:	e8 e1 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bb3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bba:	00 
f0101bbb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101bc2:	00 
f0101bc3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101bc7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101bca:	89 14 24             	mov    %edx,(%esp)
f0101bcd:	e8 f1 f5 ff ff       	call   f01011c3 <page_insert>
f0101bd2:	85 c0                	test   %eax,%eax
f0101bd4:	74 24                	je     f0101bfa <mem_init+0x97d>
f0101bd6:	c7 44 24 0c 18 47 10 	movl   $0xf0104718,0xc(%esp)
f0101bdd:	f0 
f0101bde:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101be5:	f0 
f0101be6:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0101bed:	00 
f0101bee:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101bf5:	e8 9a e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bfa:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bff:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101c04:	e8 93 ed ff ff       	call   f010099c <check_va2pa>
f0101c09:	89 da                	mov    %ebx,%edx
f0101c0b:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101c11:	c1 fa 03             	sar    $0x3,%edx
f0101c14:	c1 e2 0c             	shl    $0xc,%edx
f0101c17:	39 d0                	cmp    %edx,%eax
f0101c19:	74 24                	je     f0101c3f <mem_init+0x9c2>
f0101c1b:	c7 44 24 0c 54 47 10 	movl   $0xf0104754,0xc(%esp)
f0101c22:	f0 
f0101c23:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101c2a:	f0 
f0101c2b:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101c32:	00 
f0101c33:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101c3a:	e8 55 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c3f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c44:	74 24                	je     f0101c6a <mem_init+0x9ed>
f0101c46:	c7 44 24 0c d0 4d 10 	movl   $0xf0104dd0,0xc(%esp)
f0101c4d:	f0 
f0101c4e:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101c55:	f0 
f0101c56:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0101c5d:	00 
f0101c5e:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101c65:	e8 2a e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c6a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c71:	e8 c1 f1 ff ff       	call   f0100e37 <page_alloc>
f0101c76:	85 c0                	test   %eax,%eax
f0101c78:	74 24                	je     f0101c9e <mem_init+0xa21>
f0101c7a:	c7 44 24 0c 5c 4d 10 	movl   $0xf0104d5c,0xc(%esp)
f0101c81:	f0 
f0101c82:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101c89:	f0 
f0101c8a:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f0101c91:	00 
f0101c92:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101c99:	e8 f6 e3 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c9e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ca5:	00 
f0101ca6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101cad:	00 
f0101cae:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101cb2:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101cb7:	89 04 24             	mov    %eax,(%esp)
f0101cba:	e8 04 f5 ff ff       	call   f01011c3 <page_insert>
f0101cbf:	85 c0                	test   %eax,%eax
f0101cc1:	74 24                	je     f0101ce7 <mem_init+0xa6a>
f0101cc3:	c7 44 24 0c 18 47 10 	movl   $0xf0104718,0xc(%esp)
f0101cca:	f0 
f0101ccb:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101cd2:	f0 
f0101cd3:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0101cda:	00 
f0101cdb:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101ce2:	e8 ad e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ce7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cec:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101cf1:	e8 a6 ec ff ff       	call   f010099c <check_va2pa>
f0101cf6:	89 da                	mov    %ebx,%edx
f0101cf8:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101cfe:	c1 fa 03             	sar    $0x3,%edx
f0101d01:	c1 e2 0c             	shl    $0xc,%edx
f0101d04:	39 d0                	cmp    %edx,%eax
f0101d06:	74 24                	je     f0101d2c <mem_init+0xaaf>
f0101d08:	c7 44 24 0c 54 47 10 	movl   $0xf0104754,0xc(%esp)
f0101d0f:	f0 
f0101d10:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101d17:	f0 
f0101d18:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0101d1f:	00 
f0101d20:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101d27:	e8 68 e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101d2c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d31:	74 24                	je     f0101d57 <mem_init+0xada>
f0101d33:	c7 44 24 0c d0 4d 10 	movl   $0xf0104dd0,0xc(%esp)
f0101d3a:	f0 
f0101d3b:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101d42:	f0 
f0101d43:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0101d4a:	00 
f0101d4b:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101d52:	e8 3d e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d57:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d5e:	e8 d4 f0 ff ff       	call   f0100e37 <page_alloc>
f0101d63:	85 c0                	test   %eax,%eax
f0101d65:	74 24                	je     f0101d8b <mem_init+0xb0e>
f0101d67:	c7 44 24 0c 5c 4d 10 	movl   $0xf0104d5c,0xc(%esp)
f0101d6e:	f0 
f0101d6f:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101d76:	f0 
f0101d77:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101d7e:	00 
f0101d7f:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101d86:	e8 09 e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d8b:	8b 15 68 89 11 f0    	mov    0xf0118968,%edx
f0101d91:	8b 02                	mov    (%edx),%eax
f0101d93:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d98:	89 c1                	mov    %eax,%ecx
f0101d9a:	c1 e9 0c             	shr    $0xc,%ecx
f0101d9d:	3b 0d 64 89 11 f0    	cmp    0xf0118964,%ecx
f0101da3:	72 20                	jb     f0101dc5 <mem_init+0xb48>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101da5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101da9:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f0101db0:	f0 
f0101db1:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0101db8:	00 
f0101db9:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101dc0:	e8 cf e2 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101dc5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101dca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101dcd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101dd4:	00 
f0101dd5:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ddc:	00 
f0101ddd:	89 14 24             	mov    %edx,(%esp)
f0101de0:	e8 3b f1 ff ff       	call   f0100f20 <pgdir_walk>
f0101de5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101de8:	83 c2 04             	add    $0x4,%edx
f0101deb:	39 d0                	cmp    %edx,%eax
f0101ded:	74 24                	je     f0101e13 <mem_init+0xb96>
f0101def:	c7 44 24 0c 84 47 10 	movl   $0xf0104784,0xc(%esp)
f0101df6:	f0 
f0101df7:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101dfe:	f0 
f0101dff:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0101e06:	00 
f0101e07:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101e0e:	e8 81 e2 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101e13:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101e1a:	00 
f0101e1b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e22:	00 
f0101e23:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e27:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101e2c:	89 04 24             	mov    %eax,(%esp)
f0101e2f:	e8 8f f3 ff ff       	call   f01011c3 <page_insert>
f0101e34:	85 c0                	test   %eax,%eax
f0101e36:	74 24                	je     f0101e5c <mem_init+0xbdf>
f0101e38:	c7 44 24 0c c4 47 10 	movl   $0xf01047c4,0xc(%esp)
f0101e3f:	f0 
f0101e40:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101e47:	f0 
f0101e48:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0101e4f:	00 
f0101e50:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101e57:	e8 38 e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e5c:	8b 0d 68 89 11 f0    	mov    0xf0118968,%ecx
f0101e62:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101e65:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e6a:	89 c8                	mov    %ecx,%eax
f0101e6c:	e8 2b eb ff ff       	call   f010099c <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e71:	89 da                	mov    %ebx,%edx
f0101e73:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101e79:	c1 fa 03             	sar    $0x3,%edx
f0101e7c:	c1 e2 0c             	shl    $0xc,%edx
f0101e7f:	39 d0                	cmp    %edx,%eax
f0101e81:	74 24                	je     f0101ea7 <mem_init+0xc2a>
f0101e83:	c7 44 24 0c 54 47 10 	movl   $0xf0104754,0xc(%esp)
f0101e8a:	f0 
f0101e8b:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101e92:	f0 
f0101e93:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f0101e9a:	00 
f0101e9b:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101ea2:	e8 ed e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101ea7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101eac:	74 24                	je     f0101ed2 <mem_init+0xc55>
f0101eae:	c7 44 24 0c d0 4d 10 	movl   $0xf0104dd0,0xc(%esp)
f0101eb5:	f0 
f0101eb6:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101ebd:	f0 
f0101ebe:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0101ec5:	00 
f0101ec6:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101ecd:	e8 c2 e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ed2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ed9:	00 
f0101eda:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ee1:	00 
f0101ee2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ee5:	89 04 24             	mov    %eax,(%esp)
f0101ee8:	e8 33 f0 ff ff       	call   f0100f20 <pgdir_walk>
f0101eed:	f6 00 04             	testb  $0x4,(%eax)
f0101ef0:	75 24                	jne    f0101f16 <mem_init+0xc99>
f0101ef2:	c7 44 24 0c 04 48 10 	movl   $0xf0104804,0xc(%esp)
f0101ef9:	f0 
f0101efa:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101f01:	f0 
f0101f02:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101f09:	00 
f0101f0a:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101f11:	e8 7e e1 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101f16:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101f1b:	f6 00 04             	testb  $0x4,(%eax)
f0101f1e:	75 24                	jne    f0101f44 <mem_init+0xcc7>
f0101f20:	c7 44 24 0c e1 4d 10 	movl   $0xf0104de1,0xc(%esp)
f0101f27:	f0 
f0101f28:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101f2f:	f0 
f0101f30:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0101f37:	00 
f0101f38:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101f3f:	e8 50 e1 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f44:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f4b:	00 
f0101f4c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f53:	00 
f0101f54:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101f58:	89 04 24             	mov    %eax,(%esp)
f0101f5b:	e8 63 f2 ff ff       	call   f01011c3 <page_insert>
f0101f60:	85 c0                	test   %eax,%eax
f0101f62:	74 24                	je     f0101f88 <mem_init+0xd0b>
f0101f64:	c7 44 24 0c 18 47 10 	movl   $0xf0104718,0xc(%esp)
f0101f6b:	f0 
f0101f6c:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101f73:	f0 
f0101f74:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0101f7b:	00 
f0101f7c:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101f83:	e8 0c e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101f88:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f8f:	00 
f0101f90:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f97:	00 
f0101f98:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101f9d:	89 04 24             	mov    %eax,(%esp)
f0101fa0:	e8 7b ef ff ff       	call   f0100f20 <pgdir_walk>
f0101fa5:	f6 00 02             	testb  $0x2,(%eax)
f0101fa8:	75 24                	jne    f0101fce <mem_init+0xd51>
f0101faa:	c7 44 24 0c 38 48 10 	movl   $0xf0104838,0xc(%esp)
f0101fb1:	f0 
f0101fb2:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101fb9:	f0 
f0101fba:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f0101fc1:	00 
f0101fc2:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0101fc9:	e8 c6 e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101fce:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fd5:	00 
f0101fd6:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fdd:	00 
f0101fde:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101fe3:	89 04 24             	mov    %eax,(%esp)
f0101fe6:	e8 35 ef ff ff       	call   f0100f20 <pgdir_walk>
f0101feb:	f6 00 04             	testb  $0x4,(%eax)
f0101fee:	74 24                	je     f0102014 <mem_init+0xd97>
f0101ff0:	c7 44 24 0c 6c 48 10 	movl   $0xf010486c,0xc(%esp)
f0101ff7:	f0 
f0101ff8:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0101fff:	f0 
f0102000:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0102007:	00 
f0102008:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010200f:	e8 80 e0 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102014:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010201b:	00 
f010201c:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102023:	00 
f0102024:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102028:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010202d:	89 04 24             	mov    %eax,(%esp)
f0102030:	e8 8e f1 ff ff       	call   f01011c3 <page_insert>
f0102035:	85 c0                	test   %eax,%eax
f0102037:	78 24                	js     f010205d <mem_init+0xde0>
f0102039:	c7 44 24 0c a4 48 10 	movl   $0xf01048a4,0xc(%esp)
f0102040:	f0 
f0102041:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102048:	f0 
f0102049:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0102050:	00 
f0102051:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102058:	e8 37 e0 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010205d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102064:	00 
f0102065:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010206c:	00 
f010206d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102071:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102076:	89 04 24             	mov    %eax,(%esp)
f0102079:	e8 45 f1 ff ff       	call   f01011c3 <page_insert>
f010207e:	85 c0                	test   %eax,%eax
f0102080:	74 24                	je     f01020a6 <mem_init+0xe29>
f0102082:	c7 44 24 0c dc 48 10 	movl   $0xf01048dc,0xc(%esp)
f0102089:	f0 
f010208a:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102091:	f0 
f0102092:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f0102099:	00 
f010209a:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01020a1:	e8 ee df ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01020a6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020ad:	00 
f01020ae:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020b5:	00 
f01020b6:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01020bb:	89 04 24             	mov    %eax,(%esp)
f01020be:	e8 5d ee ff ff       	call   f0100f20 <pgdir_walk>
f01020c3:	f6 00 04             	testb  $0x4,(%eax)
f01020c6:	74 24                	je     f01020ec <mem_init+0xe6f>
f01020c8:	c7 44 24 0c 6c 48 10 	movl   $0xf010486c,0xc(%esp)
f01020cf:	f0 
f01020d0:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01020d7:	f0 
f01020d8:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f01020df:	00 
f01020e0:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01020e7:	e8 a8 df ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01020ec:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01020f1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01020f4:	ba 00 00 00 00       	mov    $0x0,%edx
f01020f9:	e8 9e e8 ff ff       	call   f010099c <check_va2pa>
f01020fe:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102101:	89 f0                	mov    %esi,%eax
f0102103:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0102109:	c1 f8 03             	sar    $0x3,%eax
f010210c:	c1 e0 0c             	shl    $0xc,%eax
f010210f:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102112:	74 24                	je     f0102138 <mem_init+0xebb>
f0102114:	c7 44 24 0c 18 49 10 	movl   $0xf0104918,0xc(%esp)
f010211b:	f0 
f010211c:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102123:	f0 
f0102124:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f010212b:	00 
f010212c:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102133:	e8 5c df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102138:	ba 00 10 00 00       	mov    $0x1000,%edx
f010213d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102140:	e8 57 e8 ff ff       	call   f010099c <check_va2pa>
f0102145:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102148:	74 24                	je     f010216e <mem_init+0xef1>
f010214a:	c7 44 24 0c 44 49 10 	movl   $0xf0104944,0xc(%esp)
f0102151:	f0 
f0102152:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102159:	f0 
f010215a:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0102161:	00 
f0102162:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102169:	e8 26 df ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010216e:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0102173:	74 24                	je     f0102199 <mem_init+0xf1c>
f0102175:	c7 44 24 0c f7 4d 10 	movl   $0xf0104df7,0xc(%esp)
f010217c:	f0 
f010217d:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102184:	f0 
f0102185:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f010218c:	00 
f010218d:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102194:	e8 fb de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102199:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010219e:	74 24                	je     f01021c4 <mem_init+0xf47>
f01021a0:	c7 44 24 0c 08 4e 10 	movl   $0xf0104e08,0xc(%esp)
f01021a7:	f0 
f01021a8:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01021af:	f0 
f01021b0:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f01021b7:	00 
f01021b8:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01021bf:	e8 d0 de ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01021c4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01021cb:	e8 67 ec ff ff       	call   f0100e37 <page_alloc>
f01021d0:	85 c0                	test   %eax,%eax
f01021d2:	74 04                	je     f01021d8 <mem_init+0xf5b>
f01021d4:	39 c3                	cmp    %eax,%ebx
f01021d6:	74 24                	je     f01021fc <mem_init+0xf7f>
f01021d8:	c7 44 24 0c 74 49 10 	movl   $0xf0104974,0xc(%esp)
f01021df:	f0 
f01021e0:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01021e7:	f0 
f01021e8:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f01021ef:	00 
f01021f0:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01021f7:	e8 98 de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01021fc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102203:	00 
f0102204:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102209:	89 04 24             	mov    %eax,(%esp)
f010220c:	e8 52 ef ff ff       	call   f0101163 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102211:	8b 15 68 89 11 f0    	mov    0xf0118968,%edx
f0102217:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010221a:	ba 00 00 00 00       	mov    $0x0,%edx
f010221f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102222:	e8 75 e7 ff ff       	call   f010099c <check_va2pa>
f0102227:	83 f8 ff             	cmp    $0xffffffff,%eax
f010222a:	74 24                	je     f0102250 <mem_init+0xfd3>
f010222c:	c7 44 24 0c 98 49 10 	movl   $0xf0104998,0xc(%esp)
f0102233:	f0 
f0102234:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010223b:	f0 
f010223c:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0102243:	00 
f0102244:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010224b:	e8 44 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102250:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102255:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102258:	e8 3f e7 ff ff       	call   f010099c <check_va2pa>
f010225d:	89 f2                	mov    %esi,%edx
f010225f:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0102265:	c1 fa 03             	sar    $0x3,%edx
f0102268:	c1 e2 0c             	shl    $0xc,%edx
f010226b:	39 d0                	cmp    %edx,%eax
f010226d:	74 24                	je     f0102293 <mem_init+0x1016>
f010226f:	c7 44 24 0c 44 49 10 	movl   $0xf0104944,0xc(%esp)
f0102276:	f0 
f0102277:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010227e:	f0 
f010227f:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0102286:	00 
f0102287:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010228e:	e8 01 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102293:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102298:	74 24                	je     f01022be <mem_init+0x1041>
f010229a:	c7 44 24 0c ae 4d 10 	movl   $0xf0104dae,0xc(%esp)
f01022a1:	f0 
f01022a2:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01022a9:	f0 
f01022aa:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f01022b1:	00 
f01022b2:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01022b9:	e8 d6 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01022be:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01022c3:	74 24                	je     f01022e9 <mem_init+0x106c>
f01022c5:	c7 44 24 0c 08 4e 10 	movl   $0xf0104e08,0xc(%esp)
f01022cc:	f0 
f01022cd:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01022d4:	f0 
f01022d5:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f01022dc:	00 
f01022dd:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01022e4:	e8 ab dd ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01022e9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01022f0:	00 
f01022f1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01022f8:	00 
f01022f9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01022fd:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102300:	89 0c 24             	mov    %ecx,(%esp)
f0102303:	e8 bb ee ff ff       	call   f01011c3 <page_insert>
f0102308:	85 c0                	test   %eax,%eax
f010230a:	74 24                	je     f0102330 <mem_init+0x10b3>
f010230c:	c7 44 24 0c bc 49 10 	movl   $0xf01049bc,0xc(%esp)
f0102313:	f0 
f0102314:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010231b:	f0 
f010231c:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f0102323:	00 
f0102324:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010232b:	e8 64 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f0102330:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102335:	75 24                	jne    f010235b <mem_init+0x10de>
f0102337:	c7 44 24 0c 19 4e 10 	movl   $0xf0104e19,0xc(%esp)
f010233e:	f0 
f010233f:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102346:	f0 
f0102347:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f010234e:	00 
f010234f:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102356:	e8 39 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f010235b:	83 3e 00             	cmpl   $0x0,(%esi)
f010235e:	74 24                	je     f0102384 <mem_init+0x1107>
f0102360:	c7 44 24 0c 25 4e 10 	movl   $0xf0104e25,0xc(%esp)
f0102367:	f0 
f0102368:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010236f:	f0 
f0102370:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f0102377:	00 
f0102378:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010237f:	e8 10 dd ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102384:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010238b:	00 
f010238c:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102391:	89 04 24             	mov    %eax,(%esp)
f0102394:	e8 ca ed ff ff       	call   f0101163 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102399:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010239e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01023a1:	ba 00 00 00 00       	mov    $0x0,%edx
f01023a6:	e8 f1 e5 ff ff       	call   f010099c <check_va2pa>
f01023ab:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023ae:	74 24                	je     f01023d4 <mem_init+0x1157>
f01023b0:	c7 44 24 0c 98 49 10 	movl   $0xf0104998,0xc(%esp)
f01023b7:	f0 
f01023b8:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01023bf:	f0 
f01023c0:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f01023c7:	00 
f01023c8:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01023cf:	e8 c0 dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01023d4:	ba 00 10 00 00       	mov    $0x1000,%edx
f01023d9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023dc:	e8 bb e5 ff ff       	call   f010099c <check_va2pa>
f01023e1:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023e4:	74 24                	je     f010240a <mem_init+0x118d>
f01023e6:	c7 44 24 0c f4 49 10 	movl   $0xf01049f4,0xc(%esp)
f01023ed:	f0 
f01023ee:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01023f5:	f0 
f01023f6:	c7 44 24 04 7e 03 00 	movl   $0x37e,0x4(%esp)
f01023fd:	00 
f01023fe:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102405:	e8 8a dc ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010240a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010240f:	74 24                	je     f0102435 <mem_init+0x11b8>
f0102411:	c7 44 24 0c 3a 4e 10 	movl   $0xf0104e3a,0xc(%esp)
f0102418:	f0 
f0102419:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102420:	f0 
f0102421:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f0102428:	00 
f0102429:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102430:	e8 5f dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102435:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010243a:	74 24                	je     f0102460 <mem_init+0x11e3>
f010243c:	c7 44 24 0c 08 4e 10 	movl   $0xf0104e08,0xc(%esp)
f0102443:	f0 
f0102444:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010244b:	f0 
f010244c:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0102453:	00 
f0102454:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010245b:	e8 34 dc ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102460:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102467:	e8 cb e9 ff ff       	call   f0100e37 <page_alloc>
f010246c:	85 c0                	test   %eax,%eax
f010246e:	74 04                	je     f0102474 <mem_init+0x11f7>
f0102470:	39 c6                	cmp    %eax,%esi
f0102472:	74 24                	je     f0102498 <mem_init+0x121b>
f0102474:	c7 44 24 0c 1c 4a 10 	movl   $0xf0104a1c,0xc(%esp)
f010247b:	f0 
f010247c:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102483:	f0 
f0102484:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f010248b:	00 
f010248c:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102493:	e8 fc db ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102498:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010249f:	e8 93 e9 ff ff       	call   f0100e37 <page_alloc>
f01024a4:	85 c0                	test   %eax,%eax
f01024a6:	74 24                	je     f01024cc <mem_init+0x124f>
f01024a8:	c7 44 24 0c 5c 4d 10 	movl   $0xf0104d5c,0xc(%esp)
f01024af:	f0 
f01024b0:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01024b7:	f0 
f01024b8:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f01024bf:	00 
f01024c0:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01024c7:	e8 c8 db ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01024cc:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01024d1:	8b 08                	mov    (%eax),%ecx
f01024d3:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01024d9:	89 fa                	mov    %edi,%edx
f01024db:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f01024e1:	c1 fa 03             	sar    $0x3,%edx
f01024e4:	c1 e2 0c             	shl    $0xc,%edx
f01024e7:	39 d1                	cmp    %edx,%ecx
f01024e9:	74 24                	je     f010250f <mem_init+0x1292>
f01024eb:	c7 44 24 0c c0 46 10 	movl   $0xf01046c0,0xc(%esp)
f01024f2:	f0 
f01024f3:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01024fa:	f0 
f01024fb:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0102502:	00 
f0102503:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010250a:	e8 85 db ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f010250f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102515:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010251a:	74 24                	je     f0102540 <mem_init+0x12c3>
f010251c:	c7 44 24 0c bf 4d 10 	movl   $0xf0104dbf,0xc(%esp)
f0102523:	f0 
f0102524:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f010252b:	f0 
f010252c:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0102533:	00 
f0102534:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f010253b:	e8 54 db ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102540:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102546:	89 3c 24             	mov    %edi,(%esp)
f0102549:	e8 67 e9 ff ff       	call   f0100eb5 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010254e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102555:	00 
f0102556:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010255d:	00 
f010255e:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102563:	89 04 24             	mov    %eax,(%esp)
f0102566:	e8 b5 e9 ff ff       	call   f0100f20 <pgdir_walk>
f010256b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010256e:	8b 0d 68 89 11 f0    	mov    0xf0118968,%ecx
f0102574:	8b 51 04             	mov    0x4(%ecx),%edx
f0102577:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010257d:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102580:	8b 15 64 89 11 f0    	mov    0xf0118964,%edx
f0102586:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0102589:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010258c:	c1 ea 0c             	shr    $0xc,%edx
f010258f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102592:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102595:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f0102598:	72 23                	jb     f01025bd <mem_init+0x1340>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010259a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010259d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01025a1:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f01025a8:	f0 
f01025a9:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f01025b0:	00 
f01025b1:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01025b8:	e8 d7 da ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01025bd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01025c0:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01025c6:	39 d0                	cmp    %edx,%eax
f01025c8:	74 24                	je     f01025ee <mem_init+0x1371>
f01025ca:	c7 44 24 0c 4b 4e 10 	movl   $0xf0104e4b,0xc(%esp)
f01025d1:	f0 
f01025d2:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01025d9:	f0 
f01025da:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f01025e1:	00 
f01025e2:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01025e9:	e8 a6 da ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01025ee:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f01025f5:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025fb:	89 f8                	mov    %edi,%eax
f01025fd:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0102603:	c1 f8 03             	sar    $0x3,%eax
f0102606:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102609:	89 c1                	mov    %eax,%ecx
f010260b:	c1 e9 0c             	shr    $0xc,%ecx
f010260e:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102611:	77 20                	ja     f0102633 <mem_init+0x13b6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102613:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102617:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f010261e:	f0 
f010261f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102626:	00 
f0102627:	c7 04 24 e0 4b 10 f0 	movl   $0xf0104be0,(%esp)
f010262e:	e8 61 da ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102633:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010263a:	00 
f010263b:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102642:	00 
	return (void *)(pa + KERNBASE);
f0102643:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102648:	89 04 24             	mov    %eax,(%esp)
f010264b:	e8 b3 13 00 00       	call   f0103a03 <memset>
	page_free(pp0);
f0102650:	89 3c 24             	mov    %edi,(%esp)
f0102653:	e8 5d e8 ff ff       	call   f0100eb5 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102658:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010265f:	00 
f0102660:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102667:	00 
f0102668:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010266d:	89 04 24             	mov    %eax,(%esp)
f0102670:	e8 ab e8 ff ff       	call   f0100f20 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102675:	89 fa                	mov    %edi,%edx
f0102677:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f010267d:	c1 fa 03             	sar    $0x3,%edx
f0102680:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102683:	89 d0                	mov    %edx,%eax
f0102685:	c1 e8 0c             	shr    $0xc,%eax
f0102688:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f010268e:	72 20                	jb     f01026b0 <mem_init+0x1433>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102690:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102694:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f010269b:	f0 
f010269c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01026a3:	00 
f01026a4:	c7 04 24 e0 4b 10 f0 	movl   $0xf0104be0,(%esp)
f01026ab:	e8 e4 d9 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01026b0:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01026b6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01026b9:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01026bf:	f6 00 01             	testb  $0x1,(%eax)
f01026c2:	74 24                	je     f01026e8 <mem_init+0x146b>
f01026c4:	c7 44 24 0c 63 4e 10 	movl   $0xf0104e63,0xc(%esp)
f01026cb:	f0 
f01026cc:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01026d3:	f0 
f01026d4:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f01026db:	00 
f01026dc:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01026e3:	e8 ac d9 ff ff       	call   f0100094 <_panic>
f01026e8:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01026eb:	39 d0                	cmp    %edx,%eax
f01026ed:	75 d0                	jne    f01026bf <mem_init+0x1442>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01026ef:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01026f4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01026fa:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// give free list back
	page_free_list = fl;
f0102700:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102703:	89 0d 40 85 11 f0    	mov    %ecx,0xf0118540

	// free the pages we took
	page_free(pp0);
f0102709:	89 3c 24             	mov    %edi,(%esp)
f010270c:	e8 a4 e7 ff ff       	call   f0100eb5 <page_free>
	page_free(pp1);
f0102711:	89 34 24             	mov    %esi,(%esp)
f0102714:	e8 9c e7 ff ff       	call   f0100eb5 <page_free>
	page_free(pp2);
f0102719:	89 1c 24             	mov    %ebx,(%esp)
f010271c:	e8 94 e7 ff ff       	call   f0100eb5 <page_free>

	cprintf("check_page() succeeded!\n");
f0102721:	c7 04 24 7a 4e 10 f0 	movl   $0xf0104e7a,(%esp)
f0102728:	e8 ad 07 00 00       	call   f0102eda <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, UPAGES, ROUNDUP((sizeof(struct PageInfo) * npages), PGSIZE), PADDR(pages), (PTE_U | PTE_P));
f010272d:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102732:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102737:	77 20                	ja     f0102759 <mem_init+0x14dc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102739:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010273d:	c7 44 24 08 34 45 10 	movl   $0xf0104534,0x8(%esp)
f0102744:	f0 
f0102745:	c7 44 24 04 b3 00 00 	movl   $0xb3,0x4(%esp)
f010274c:	00 
f010274d:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102754:	e8 3b d9 ff ff       	call   f0100094 <_panic>
f0102759:	8b 15 64 89 11 f0    	mov    0xf0118964,%edx
f010275f:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102766:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010276c:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102773:	00 
	return (physaddr_t)kva - KERNBASE;
f0102774:	05 00 00 00 10       	add    $0x10000000,%eax
f0102779:	89 04 24             	mov    %eax,(%esp)
f010277c:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102781:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102786:	e8 ba e8 ff ff       	call   f0101045 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010278b:	be 00 e0 10 f0       	mov    $0xf010e000,%esi
f0102790:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102796:	77 20                	ja     f01027b8 <mem_init+0x153b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102798:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010279c:	c7 44 24 08 34 45 10 	movl   $0xf0104534,0x8(%esp)
f01027a3:	f0 
f01027a4:	c7 44 24 04 c1 00 00 	movl   $0xc1,0x4(%esp)
f01027ab:	00 
f01027ac:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01027b3:	e8 dc d8 ff ff       	call   f0100094 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, (KSTACKTOP - KSTKSIZE), KSTKSIZE, PADDR(bootstack), (PTE_W | PTE_P));
f01027b8:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01027bf:	00 
f01027c0:	c7 04 24 00 e0 10 00 	movl   $0x10e000,(%esp)
f01027c7:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01027cc:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01027d1:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01027d6:	e8 6a e8 ff ff       	call   f0101045 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, KERNBASE, ROUNDUP(0xFFFFFFFF-KERNBASE,PGSIZE), 0, (PTE_W | PTE_P));
f01027db:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01027e2:	00 
f01027e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027ea:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01027ef:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027f4:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01027f9:	e8 47 e8 ff ff       	call   f0101045 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01027fe:	8b 1d 68 89 11 f0    	mov    0xf0118968,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102804:	8b 35 64 89 11 f0    	mov    0xf0118964,%esi
f010280a:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010280d:	8d 3c f5 ff 0f 00 00 	lea    0xfff(,%esi,8),%edi
f0102814:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	for (i = 0; i < n; i += PGSIZE)
f010281a:	be 00 00 00 00       	mov    $0x0,%esi
f010281f:	eb 70                	jmp    f0102891 <mem_init+0x1614>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102821:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102827:	89 d8                	mov    %ebx,%eax
f0102829:	e8 6e e1 ff ff       	call   f010099c <check_va2pa>
f010282e:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102834:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010283a:	77 20                	ja     f010285c <mem_init+0x15df>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010283c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102840:	c7 44 24 08 34 45 10 	movl   $0xf0104534,0x8(%esp)
f0102847:	f0 
f0102848:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f010284f:	00 
f0102850:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102857:	e8 38 d8 ff ff       	call   f0100094 <_panic>
f010285c:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102863:	39 d0                	cmp    %edx,%eax
f0102865:	74 24                	je     f010288b <mem_init+0x160e>
f0102867:	c7 44 24 0c 40 4a 10 	movl   $0xf0104a40,0xc(%esp)
f010286e:	f0 
f010286f:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102876:	f0 
f0102877:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f010287e:	00 
f010287f:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102886:	e8 09 d8 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010288b:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102891:	39 f7                	cmp    %esi,%edi
f0102893:	77 8c                	ja     f0102821 <mem_init+0x15a4>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102895:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102898:	c1 e7 0c             	shl    $0xc,%edi
f010289b:	be 00 00 00 00       	mov    $0x0,%esi
f01028a0:	eb 3b                	jmp    f01028dd <mem_init+0x1660>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01028a2:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01028a8:	89 d8                	mov    %ebx,%eax
f01028aa:	e8 ed e0 ff ff       	call   f010099c <check_va2pa>
f01028af:	39 c6                	cmp    %eax,%esi
f01028b1:	74 24                	je     f01028d7 <mem_init+0x165a>
f01028b3:	c7 44 24 0c 74 4a 10 	movl   $0xf0104a74,0xc(%esp)
f01028ba:	f0 
f01028bb:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01028c2:	f0 
f01028c3:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
f01028ca:	00 
f01028cb:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01028d2:	e8 bd d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028d7:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01028dd:	39 fe                	cmp    %edi,%esi
f01028df:	72 c1                	jb     f01028a2 <mem_init+0x1625>
f01028e1:	be 00 80 ff ef       	mov    $0xefff8000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01028e6:	bf 00 e0 10 f0       	mov    $0xf010e000,%edi
f01028eb:	81 c7 00 80 00 20    	add    $0x20008000,%edi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01028f1:	89 f2                	mov    %esi,%edx
f01028f3:	89 d8                	mov    %ebx,%eax
f01028f5:	e8 a2 e0 ff ff       	call   f010099c <check_va2pa>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01028fa:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01028fd:	39 d0                	cmp    %edx,%eax
f01028ff:	74 24                	je     f0102925 <mem_init+0x16a8>
f0102901:	c7 44 24 0c 9c 4a 10 	movl   $0xf0104a9c,0xc(%esp)
f0102908:	f0 
f0102909:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102910:	f0 
f0102911:	c7 44 24 04 e8 02 00 	movl   $0x2e8,0x4(%esp)
f0102918:	00 
f0102919:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102920:	e8 6f d7 ff ff       	call   f0100094 <_panic>
f0102925:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010292b:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102931:	75 be                	jne    f01028f1 <mem_init+0x1674>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102933:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102938:	89 d8                	mov    %ebx,%eax
f010293a:	e8 5d e0 ff ff       	call   f010099c <check_va2pa>
f010293f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102942:	74 24                	je     f0102968 <mem_init+0x16eb>
f0102944:	c7 44 24 0c e4 4a 10 	movl   $0xf0104ae4,0xc(%esp)
f010294b:	f0 
f010294c:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102953:	f0 
f0102954:	c7 44 24 04 e9 02 00 	movl   $0x2e9,0x4(%esp)
f010295b:	00 
f010295c:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102963:	e8 2c d7 ff ff       	call   f0100094 <_panic>
f0102968:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010296d:	ba 01 00 00 00       	mov    $0x1,%edx
f0102972:	8d 88 44 fc ff ff    	lea    -0x3bc(%eax),%ecx
f0102978:	83 f9 03             	cmp    $0x3,%ecx
f010297b:	77 39                	ja     f01029b6 <mem_init+0x1739>
f010297d:	89 d6                	mov    %edx,%esi
f010297f:	d3 e6                	shl    %cl,%esi
f0102981:	89 f1                	mov    %esi,%ecx
f0102983:	f6 c1 0b             	test   $0xb,%cl
f0102986:	74 2e                	je     f01029b6 <mem_init+0x1739>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102988:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010298c:	0f 85 aa 00 00 00    	jne    f0102a3c <mem_init+0x17bf>
f0102992:	c7 44 24 0c 93 4e 10 	movl   $0xf0104e93,0xc(%esp)
f0102999:	f0 
f010299a:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01029a1:	f0 
f01029a2:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f01029a9:	00 
f01029aa:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01029b1:	e8 de d6 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01029b6:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01029bb:	76 55                	jbe    f0102a12 <mem_init+0x1795>
				assert(pgdir[i] & PTE_P);
f01029bd:	8b 0c 83             	mov    (%ebx,%eax,4),%ecx
f01029c0:	f6 c1 01             	test   $0x1,%cl
f01029c3:	75 24                	jne    f01029e9 <mem_init+0x176c>
f01029c5:	c7 44 24 0c 93 4e 10 	movl   $0xf0104e93,0xc(%esp)
f01029cc:	f0 
f01029cd:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01029d4:	f0 
f01029d5:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f01029dc:	00 
f01029dd:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f01029e4:	e8 ab d6 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f01029e9:	f6 c1 02             	test   $0x2,%cl
f01029ec:	75 4e                	jne    f0102a3c <mem_init+0x17bf>
f01029ee:	c7 44 24 0c a4 4e 10 	movl   $0xf0104ea4,0xc(%esp)
f01029f5:	f0 
f01029f6:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f01029fd:	f0 
f01029fe:	c7 44 24 04 f6 02 00 	movl   $0x2f6,0x4(%esp)
f0102a05:	00 
f0102a06:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102a0d:	e8 82 d6 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102a12:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102a16:	74 24                	je     f0102a3c <mem_init+0x17bf>
f0102a18:	c7 44 24 0c b5 4e 10 	movl   $0xf0104eb5,0xc(%esp)
f0102a1f:	f0 
f0102a20:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102a27:	f0 
f0102a28:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0102a2f:	00 
f0102a30:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102a37:	e8 58 d6 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102a3c:	83 c0 01             	add    $0x1,%eax
f0102a3f:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102a44:	0f 85 28 ff ff ff    	jne    f0102972 <mem_init+0x16f5>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a4a:	c7 04 24 14 4b 10 f0 	movl   $0xf0104b14,(%esp)
f0102a51:	e8 84 04 00 00       	call   f0102eda <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102a56:	a1 68 89 11 f0       	mov    0xf0118968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a5b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a60:	77 20                	ja     f0102a82 <mem_init+0x1805>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a62:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a66:	c7 44 24 08 34 45 10 	movl   $0xf0104534,0x8(%esp)
f0102a6d:	f0 
f0102a6e:	c7 44 24 04 d8 00 00 	movl   $0xd8,0x4(%esp)
f0102a75:	00 
f0102a76:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102a7d:	e8 12 d6 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102a82:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102a87:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102a8a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a8f:	e8 ab df ff ff       	call   f0100a3f <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102a94:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0102a97:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102a9c:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102a9f:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102aa2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102aa9:	e8 89 e3 ff ff       	call   f0100e37 <page_alloc>
f0102aae:	89 c6                	mov    %eax,%esi
f0102ab0:	85 c0                	test   %eax,%eax
f0102ab2:	75 24                	jne    f0102ad8 <mem_init+0x185b>
f0102ab4:	c7 44 24 0c b1 4c 10 	movl   $0xf0104cb1,0xc(%esp)
f0102abb:	f0 
f0102abc:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102ac3:	f0 
f0102ac4:	c7 44 24 04 b8 03 00 	movl   $0x3b8,0x4(%esp)
f0102acb:	00 
f0102acc:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102ad3:	e8 bc d5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102ad8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102adf:	e8 53 e3 ff ff       	call   f0100e37 <page_alloc>
f0102ae4:	89 c7                	mov    %eax,%edi
f0102ae6:	85 c0                	test   %eax,%eax
f0102ae8:	75 24                	jne    f0102b0e <mem_init+0x1891>
f0102aea:	c7 44 24 0c c7 4c 10 	movl   $0xf0104cc7,0xc(%esp)
f0102af1:	f0 
f0102af2:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102af9:	f0 
f0102afa:	c7 44 24 04 b9 03 00 	movl   $0x3b9,0x4(%esp)
f0102b01:	00 
f0102b02:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102b09:	e8 86 d5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102b0e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b15:	e8 1d e3 ff ff       	call   f0100e37 <page_alloc>
f0102b1a:	89 c3                	mov    %eax,%ebx
f0102b1c:	85 c0                	test   %eax,%eax
f0102b1e:	75 24                	jne    f0102b44 <mem_init+0x18c7>
f0102b20:	c7 44 24 0c dd 4c 10 	movl   $0xf0104cdd,0xc(%esp)
f0102b27:	f0 
f0102b28:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102b2f:	f0 
f0102b30:	c7 44 24 04 ba 03 00 	movl   $0x3ba,0x4(%esp)
f0102b37:	00 
f0102b38:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102b3f:	e8 50 d5 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102b44:	89 34 24             	mov    %esi,(%esp)
f0102b47:	e8 69 e3 ff ff       	call   f0100eb5 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b4c:	89 f8                	mov    %edi,%eax
f0102b4e:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0102b54:	c1 f8 03             	sar    $0x3,%eax
f0102b57:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b5a:	89 c2                	mov    %eax,%edx
f0102b5c:	c1 ea 0c             	shr    $0xc,%edx
f0102b5f:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0102b65:	72 20                	jb     f0102b87 <mem_init+0x190a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b67:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b6b:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f0102b72:	f0 
f0102b73:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102b7a:	00 
f0102b7b:	c7 04 24 e0 4b 10 f0 	movl   $0xf0104be0,(%esp)
f0102b82:	e8 0d d5 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b87:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b8e:	00 
f0102b8f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102b96:	00 
	return (void *)(pa + KERNBASE);
f0102b97:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b9c:	89 04 24             	mov    %eax,(%esp)
f0102b9f:	e8 5f 0e 00 00       	call   f0103a03 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ba4:	89 d8                	mov    %ebx,%eax
f0102ba6:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0102bac:	c1 f8 03             	sar    $0x3,%eax
f0102baf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bb2:	89 c2                	mov    %eax,%edx
f0102bb4:	c1 ea 0c             	shr    $0xc,%edx
f0102bb7:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0102bbd:	72 20                	jb     f0102bdf <mem_init+0x1962>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bbf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bc3:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f0102bca:	f0 
f0102bcb:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102bd2:	00 
f0102bd3:	c7 04 24 e0 4b 10 f0 	movl   $0xf0104be0,(%esp)
f0102bda:	e8 b5 d4 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102bdf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102be6:	00 
f0102be7:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102bee:	00 
	return (void *)(pa + KERNBASE);
f0102bef:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bf4:	89 04 24             	mov    %eax,(%esp)
f0102bf7:	e8 07 0e 00 00       	call   f0103a03 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102bfc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c03:	00 
f0102c04:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c0b:	00 
f0102c0c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102c10:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102c15:	89 04 24             	mov    %eax,(%esp)
f0102c18:	e8 a6 e5 ff ff       	call   f01011c3 <page_insert>
	assert(pp1->pp_ref == 1);
f0102c1d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c22:	74 24                	je     f0102c48 <mem_init+0x19cb>
f0102c24:	c7 44 24 0c ae 4d 10 	movl   $0xf0104dae,0xc(%esp)
f0102c2b:	f0 
f0102c2c:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102c33:	f0 
f0102c34:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f0102c3b:	00 
f0102c3c:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102c43:	e8 4c d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c48:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c4f:	01 01 01 
f0102c52:	74 24                	je     f0102c78 <mem_init+0x19fb>
f0102c54:	c7 44 24 0c 34 4b 10 	movl   $0xf0104b34,0xc(%esp)
f0102c5b:	f0 
f0102c5c:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102c63:	f0 
f0102c64:	c7 44 24 04 c0 03 00 	movl   $0x3c0,0x4(%esp)
f0102c6b:	00 
f0102c6c:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102c73:	e8 1c d4 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c78:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c7f:	00 
f0102c80:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c87:	00 
f0102c88:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102c8c:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102c91:	89 04 24             	mov    %eax,(%esp)
f0102c94:	e8 2a e5 ff ff       	call   f01011c3 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c99:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102ca0:	02 02 02 
f0102ca3:	74 24                	je     f0102cc9 <mem_init+0x1a4c>
f0102ca5:	c7 44 24 0c 58 4b 10 	movl   $0xf0104b58,0xc(%esp)
f0102cac:	f0 
f0102cad:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102cb4:	f0 
f0102cb5:	c7 44 24 04 c2 03 00 	movl   $0x3c2,0x4(%esp)
f0102cbc:	00 
f0102cbd:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102cc4:	e8 cb d3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102cc9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102cce:	74 24                	je     f0102cf4 <mem_init+0x1a77>
f0102cd0:	c7 44 24 0c d0 4d 10 	movl   $0xf0104dd0,0xc(%esp)
f0102cd7:	f0 
f0102cd8:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102cdf:	f0 
f0102ce0:	c7 44 24 04 c3 03 00 	movl   $0x3c3,0x4(%esp)
f0102ce7:	00 
f0102ce8:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102cef:	e8 a0 d3 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102cf4:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102cf9:	74 24                	je     f0102d1f <mem_init+0x1aa2>
f0102cfb:	c7 44 24 0c 3a 4e 10 	movl   $0xf0104e3a,0xc(%esp)
f0102d02:	f0 
f0102d03:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102d0a:	f0 
f0102d0b:	c7 44 24 04 c4 03 00 	movl   $0x3c4,0x4(%esp)
f0102d12:	00 
f0102d13:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102d1a:	e8 75 d3 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d1f:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d26:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d29:	89 d8                	mov    %ebx,%eax
f0102d2b:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0102d31:	c1 f8 03             	sar    $0x3,%eax
f0102d34:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d37:	89 c2                	mov    %eax,%edx
f0102d39:	c1 ea 0c             	shr    $0xc,%edx
f0102d3c:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0102d42:	72 20                	jb     f0102d64 <mem_init+0x1ae7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d44:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d48:	c7 44 24 08 24 44 10 	movl   $0xf0104424,0x8(%esp)
f0102d4f:	f0 
f0102d50:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102d57:	00 
f0102d58:	c7 04 24 e0 4b 10 f0 	movl   $0xf0104be0,(%esp)
f0102d5f:	e8 30 d3 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d64:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d6b:	03 03 03 
f0102d6e:	74 24                	je     f0102d94 <mem_init+0x1b17>
f0102d70:	c7 44 24 0c 7c 4b 10 	movl   $0xf0104b7c,0xc(%esp)
f0102d77:	f0 
f0102d78:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102d7f:	f0 
f0102d80:	c7 44 24 04 c6 03 00 	movl   $0x3c6,0x4(%esp)
f0102d87:	00 
f0102d88:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102d8f:	e8 00 d3 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d94:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102d9b:	00 
f0102d9c:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102da1:	89 04 24             	mov    %eax,(%esp)
f0102da4:	e8 ba e3 ff ff       	call   f0101163 <page_remove>
	assert(pp2->pp_ref == 0);
f0102da9:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102dae:	74 24                	je     f0102dd4 <mem_init+0x1b57>
f0102db0:	c7 44 24 0c 08 4e 10 	movl   $0xf0104e08,0xc(%esp)
f0102db7:	f0 
f0102db8:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102dbf:	f0 
f0102dc0:	c7 44 24 04 c8 03 00 	movl   $0x3c8,0x4(%esp)
f0102dc7:	00 
f0102dc8:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102dcf:	e8 c0 d2 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102dd4:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102dd9:	8b 08                	mov    (%eax),%ecx
f0102ddb:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102de1:	89 f2                	mov    %esi,%edx
f0102de3:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0102de9:	c1 fa 03             	sar    $0x3,%edx
f0102dec:	c1 e2 0c             	shl    $0xc,%edx
f0102def:	39 d1                	cmp    %edx,%ecx
f0102df1:	74 24                	je     f0102e17 <mem_init+0x1b9a>
f0102df3:	c7 44 24 0c c0 46 10 	movl   $0xf01046c0,0xc(%esp)
f0102dfa:	f0 
f0102dfb:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102e02:	f0 
f0102e03:	c7 44 24 04 cb 03 00 	movl   $0x3cb,0x4(%esp)
f0102e0a:	00 
f0102e0b:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102e12:	e8 7d d2 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102e17:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102e1d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e22:	74 24                	je     f0102e48 <mem_init+0x1bcb>
f0102e24:	c7 44 24 0c bf 4d 10 	movl   $0xf0104dbf,0xc(%esp)
f0102e2b:	f0 
f0102e2c:	c7 44 24 08 fa 4b 10 	movl   $0xf0104bfa,0x8(%esp)
f0102e33:	f0 
f0102e34:	c7 44 24 04 cd 03 00 	movl   $0x3cd,0x4(%esp)
f0102e3b:	00 
f0102e3c:	c7 04 24 d4 4b 10 f0 	movl   $0xf0104bd4,(%esp)
f0102e43:	e8 4c d2 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102e48:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102e4e:	89 34 24             	mov    %esi,(%esp)
f0102e51:	e8 5f e0 ff ff       	call   f0100eb5 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e56:	c7 04 24 a8 4b 10 f0 	movl   $0xf0104ba8,(%esp)
f0102e5d:	e8 78 00 00 00       	call   f0102eda <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102e62:	83 c4 3c             	add    $0x3c,%esp
f0102e65:	5b                   	pop    %ebx
f0102e66:	5e                   	pop    %esi
f0102e67:	5f                   	pop    %edi
f0102e68:	5d                   	pop    %ebp
f0102e69:	c3                   	ret    
	...

f0102e6c <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102e6c:	55                   	push   %ebp
f0102e6d:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e6f:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e74:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e77:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102e78:	b2 71                	mov    $0x71,%dl
f0102e7a:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102e7b:	0f b6 c0             	movzbl %al,%eax
}
f0102e7e:	5d                   	pop    %ebp
f0102e7f:	c3                   	ret    

f0102e80 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102e80:	55                   	push   %ebp
f0102e81:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e83:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e88:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e8b:	ee                   	out    %al,(%dx)
f0102e8c:	b2 71                	mov    $0x71,%dl
f0102e8e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e91:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102e92:	5d                   	pop    %ebp
f0102e93:	c3                   	ret    

f0102e94 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102e94:	55                   	push   %ebp
f0102e95:	89 e5                	mov    %esp,%ebp
f0102e97:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102e9a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e9d:	89 04 24             	mov    %eax,(%esp)
f0102ea0:	e8 3c d7 ff ff       	call   f01005e1 <cputchar>
	*cnt++;
}
f0102ea5:	c9                   	leave  
f0102ea6:	c3                   	ret    

f0102ea7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102ea7:	55                   	push   %ebp
f0102ea8:	89 e5                	mov    %esp,%ebp
f0102eaa:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102ead:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102eb4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102eb7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ebb:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ebe:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102ec2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102ec5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102ec9:	c7 04 24 94 2e 10 f0 	movl   $0xf0102e94,(%esp)
f0102ed0:	e8 98 04 00 00       	call   f010336d <vprintfmt>
	return cnt;
}
f0102ed5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102ed8:	c9                   	leave  
f0102ed9:	c3                   	ret    

f0102eda <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102eda:	55                   	push   %ebp
f0102edb:	89 e5                	mov    %esp,%ebp
f0102edd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102ee0:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102ee3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102ee7:	8b 45 08             	mov    0x8(%ebp),%eax
f0102eea:	89 04 24             	mov    %eax,(%esp)
f0102eed:	e8 b5 ff ff ff       	call   f0102ea7 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102ef2:	c9                   	leave  
f0102ef3:	c3                   	ret    
	...

f0102f00 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102f00:	55                   	push   %ebp
f0102f01:	89 e5                	mov    %esp,%ebp
f0102f03:	57                   	push   %edi
f0102f04:	56                   	push   %esi
f0102f05:	53                   	push   %ebx
f0102f06:	83 ec 10             	sub    $0x10,%esp
f0102f09:	89 c3                	mov    %eax,%ebx
f0102f0b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102f0e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102f11:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102f14:	8b 0a                	mov    (%edx),%ecx
f0102f16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f19:	8b 00                	mov    (%eax),%eax
f0102f1b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102f1e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102f25:	eb 77                	jmp    f0102f9e <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0102f27:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102f2a:	01 c8                	add    %ecx,%eax
f0102f2c:	bf 02 00 00 00       	mov    $0x2,%edi
f0102f31:	99                   	cltd   
f0102f32:	f7 ff                	idiv   %edi
f0102f34:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102f36:	eb 01                	jmp    f0102f39 <stab_binsearch+0x39>
			m--;
f0102f38:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102f39:	39 ca                	cmp    %ecx,%edx
f0102f3b:	7c 1d                	jl     f0102f5a <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102f3d:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102f40:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0102f45:	39 f7                	cmp    %esi,%edi
f0102f47:	75 ef                	jne    f0102f38 <stab_binsearch+0x38>
f0102f49:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102f4c:	6b fa 0c             	imul   $0xc,%edx,%edi
f0102f4f:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0102f53:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102f56:	73 18                	jae    f0102f70 <stab_binsearch+0x70>
f0102f58:	eb 05                	jmp    f0102f5f <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102f5a:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0102f5d:	eb 3f                	jmp    f0102f9e <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102f5f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102f62:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0102f64:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102f67:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102f6e:	eb 2e                	jmp    f0102f9e <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102f70:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102f73:	76 15                	jbe    f0102f8a <stab_binsearch+0x8a>
			*region_right = m - 1;
f0102f75:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102f78:	4f                   	dec    %edi
f0102f79:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0102f7c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f7f:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102f81:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102f88:	eb 14                	jmp    f0102f9e <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102f8a:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102f8d:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102f90:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0102f92:	ff 45 0c             	incl   0xc(%ebp)
f0102f95:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102f97:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102f9e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0102fa1:	7e 84                	jle    f0102f27 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102fa3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102fa7:	75 0d                	jne    f0102fb6 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0102fa9:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102fac:	8b 02                	mov    (%edx),%eax
f0102fae:	48                   	dec    %eax
f0102faf:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102fb2:	89 01                	mov    %eax,(%ecx)
f0102fb4:	eb 22                	jmp    f0102fd8 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102fb6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102fb9:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102fbb:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102fbe:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102fc0:	eb 01                	jmp    f0102fc3 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102fc2:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102fc3:	39 c1                	cmp    %eax,%ecx
f0102fc5:	7d 0c                	jge    f0102fd3 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102fc7:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102fca:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0102fcf:	39 f2                	cmp    %esi,%edx
f0102fd1:	75 ef                	jne    f0102fc2 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102fd3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102fd6:	89 02                	mov    %eax,(%edx)
	}
}
f0102fd8:	83 c4 10             	add    $0x10,%esp
f0102fdb:	5b                   	pop    %ebx
f0102fdc:	5e                   	pop    %esi
f0102fdd:	5f                   	pop    %edi
f0102fde:	5d                   	pop    %ebp
f0102fdf:	c3                   	ret    

f0102fe0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102fe0:	55                   	push   %ebp
f0102fe1:	89 e5                	mov    %esp,%ebp
f0102fe3:	83 ec 58             	sub    $0x58,%esp
f0102fe6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102fe9:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102fec:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102fef:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ff2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102ff5:	c7 03 c3 4e 10 f0    	movl   $0xf0104ec3,(%ebx)
	info->eip_line = 0;
f0102ffb:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103002:	c7 43 08 c3 4e 10 f0 	movl   $0xf0104ec3,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0103009:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103010:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103013:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010301a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103020:	76 12                	jbe    f0103034 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103022:	b8 d3 d0 10 f0       	mov    $0xf010d0d3,%eax
f0103027:	3d 79 b2 10 f0       	cmp    $0xf010b279,%eax
f010302c:	0f 86 b2 01 00 00    	jbe    f01031e4 <debuginfo_eip+0x204>
f0103032:	eb 1c                	jmp    f0103050 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0103034:	c7 44 24 08 cd 4e 10 	movl   $0xf0104ecd,0x8(%esp)
f010303b:	f0 
f010303c:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0103043:	00 
f0103044:	c7 04 24 da 4e 10 f0 	movl   $0xf0104eda,(%esp)
f010304b:	e8 44 d0 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103050:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103055:	80 3d d2 d0 10 f0 00 	cmpb   $0x0,0xf010d0d2
f010305c:	0f 85 8e 01 00 00    	jne    f01031f0 <debuginfo_eip+0x210>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103062:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103069:	b8 78 b2 10 f0       	mov    $0xf010b278,%eax
f010306e:	2d 10 51 10 f0       	sub    $0xf0105110,%eax
f0103073:	c1 f8 02             	sar    $0x2,%eax
f0103076:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010307c:	83 e8 01             	sub    $0x1,%eax
f010307f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103082:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103086:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f010308d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103090:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103093:	b8 10 51 10 f0       	mov    $0xf0105110,%eax
f0103098:	e8 63 fe ff ff       	call   f0102f00 <stab_binsearch>
	if (lfile == 0)
f010309d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f01030a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f01030a5:	85 d2                	test   %edx,%edx
f01030a7:	0f 84 43 01 00 00    	je     f01031f0 <debuginfo_eip+0x210>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01030ad:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f01030b0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030b3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01030b6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01030ba:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01030c1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01030c4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01030c7:	b8 10 51 10 f0       	mov    $0xf0105110,%eax
f01030cc:	e8 2f fe ff ff       	call   f0102f00 <stab_binsearch>

	if (lfun <= rfun) {
f01030d1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01030d4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01030d7:	39 d0                	cmp    %edx,%eax
f01030d9:	7f 3d                	jg     f0103118 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01030db:	6b c8 0c             	imul   $0xc,%eax,%ecx
f01030de:	8d b9 10 51 10 f0    	lea    -0xfefaef0(%ecx),%edi
f01030e4:	89 7d c0             	mov    %edi,-0x40(%ebp)
f01030e7:	8b 89 10 51 10 f0    	mov    -0xfefaef0(%ecx),%ecx
f01030ed:	bf d3 d0 10 f0       	mov    $0xf010d0d3,%edi
f01030f2:	81 ef 79 b2 10 f0    	sub    $0xf010b279,%edi
f01030f8:	39 f9                	cmp    %edi,%ecx
f01030fa:	73 09                	jae    f0103105 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01030fc:	81 c1 79 b2 10 f0    	add    $0xf010b279,%ecx
f0103102:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103105:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103108:	8b 4f 08             	mov    0x8(%edi),%ecx
f010310b:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010310e:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103110:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103113:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0103116:	eb 0f                	jmp    f0103127 <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103118:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010311b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010311e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103121:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103124:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103127:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f010312e:	00 
f010312f:	8b 43 08             	mov    0x8(%ebx),%eax
f0103132:	89 04 24             	mov    %eax,(%esp)
f0103135:	e8 ad 08 00 00       	call   f01039e7 <strfind>
f010313a:	2b 43 08             	sub    0x8(%ebx),%eax
f010313d:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103140:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103144:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010314b:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010314e:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103151:	b8 10 51 10 f0       	mov    $0xf0105110,%eax
f0103156:	e8 a5 fd ff ff       	call   f0102f00 <stab_binsearch>

	if (lline <= rline){
f010315b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
		info->eip_line = stabs[lline].n_desc;
	}else{
		return -1;
f010315e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);

	if (lline <= rline){
f0103163:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0103166:	0f 8f 84 00 00 00    	jg     f01031f0 <debuginfo_eip+0x210>
		info->eip_line = stabs[lline].n_desc;
f010316c:	6b d2 0c             	imul   $0xc,%edx,%edx
f010316f:	0f b7 82 16 51 10 f0 	movzwl -0xfefaeea(%edx),%eax
f0103176:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103179:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010317c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010317f:	eb 03                	jmp    f0103184 <debuginfo_eip+0x1a4>
f0103181:	83 e8 01             	sub    $0x1,%eax
f0103184:	89 c6                	mov    %eax,%esi
f0103186:	39 c7                	cmp    %eax,%edi
f0103188:	7f 27                	jg     f01031b1 <debuginfo_eip+0x1d1>
	       && stabs[lline].n_type != N_SOL
f010318a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010318d:	8d 0c 95 10 51 10 f0 	lea    -0xfefaef0(,%edx,4),%ecx
f0103194:	0f b6 51 04          	movzbl 0x4(%ecx),%edx
f0103198:	80 fa 84             	cmp    $0x84,%dl
f010319b:	74 60                	je     f01031fd <debuginfo_eip+0x21d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010319d:	80 fa 64             	cmp    $0x64,%dl
f01031a0:	75 df                	jne    f0103181 <debuginfo_eip+0x1a1>
f01031a2:	83 79 08 00          	cmpl   $0x0,0x8(%ecx)
f01031a6:	74 d9                	je     f0103181 <debuginfo_eip+0x1a1>
f01031a8:	eb 53                	jmp    f01031fd <debuginfo_eip+0x21d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f01031aa:	05 79 b2 10 f0       	add    $0xf010b279,%eax
f01031af:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01031b1:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01031b4:	8b 55 d8             	mov    -0x28(%ebp),%edx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01031b7:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01031bc:	39 d1                	cmp    %edx,%ecx
f01031be:	7d 30                	jge    f01031f0 <debuginfo_eip+0x210>
		for (lline = lfun + 1;
f01031c0:	8d 41 01             	lea    0x1(%ecx),%eax
f01031c3:	eb 04                	jmp    f01031c9 <debuginfo_eip+0x1e9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01031c5:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01031c9:	39 d0                	cmp    %edx,%eax
f01031cb:	7d 1e                	jge    f01031eb <debuginfo_eip+0x20b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01031cd:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01031d0:	83 c0 01             	add    $0x1,%eax
f01031d3:	80 3c 8d 14 51 10 f0 	cmpb   $0xa0,-0xfefaeec(,%ecx,4)
f01031da:	a0 
f01031db:	74 e8                	je     f01031c5 <debuginfo_eip+0x1e5>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01031dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01031e2:	eb 0c                	jmp    f01031f0 <debuginfo_eip+0x210>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01031e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01031e9:	eb 05                	jmp    f01031f0 <debuginfo_eip+0x210>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01031eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031f0:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01031f3:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01031f6:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01031f9:	89 ec                	mov    %ebp,%esp
f01031fb:	5d                   	pop    %ebp
f01031fc:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01031fd:	6b f6 0c             	imul   $0xc,%esi,%esi
f0103200:	8b 86 10 51 10 f0    	mov    -0xfefaef0(%esi),%eax
f0103206:	ba d3 d0 10 f0       	mov    $0xf010d0d3,%edx
f010320b:	81 ea 79 b2 10 f0    	sub    $0xf010b279,%edx
f0103211:	39 d0                	cmp    %edx,%eax
f0103213:	72 95                	jb     f01031aa <debuginfo_eip+0x1ca>
f0103215:	eb 9a                	jmp    f01031b1 <debuginfo_eip+0x1d1>
	...

f0103220 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103220:	55                   	push   %ebp
f0103221:	89 e5                	mov    %esp,%ebp
f0103223:	57                   	push   %edi
f0103224:	56                   	push   %esi
f0103225:	53                   	push   %ebx
f0103226:	83 ec 3c             	sub    $0x3c,%esp
f0103229:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010322c:	89 d7                	mov    %edx,%edi
f010322e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103231:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103234:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103237:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010323a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010323d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103240:	85 c0                	test   %eax,%eax
f0103242:	75 08                	jne    f010324c <printnum+0x2c>
f0103244:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103247:	39 45 10             	cmp    %eax,0x10(%ebp)
f010324a:	77 59                	ja     f01032a5 <printnum+0x85>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010324c:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103250:	83 eb 01             	sub    $0x1,%ebx
f0103253:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103257:	8b 45 10             	mov    0x10(%ebp),%eax
f010325a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010325e:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103262:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103266:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010326d:	00 
f010326e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103271:	89 04 24             	mov    %eax,(%esp)
f0103274:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103277:	89 44 24 04          	mov    %eax,0x4(%esp)
f010327b:	e8 b0 09 00 00       	call   f0103c30 <__udivdi3>
f0103280:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103284:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103288:	89 04 24             	mov    %eax,(%esp)
f010328b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010328f:	89 fa                	mov    %edi,%edx
f0103291:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103294:	e8 87 ff ff ff       	call   f0103220 <printnum>
f0103299:	eb 11                	jmp    f01032ac <printnum+0x8c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010329b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010329f:	89 34 24             	mov    %esi,(%esp)
f01032a2:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01032a5:	83 eb 01             	sub    $0x1,%ebx
f01032a8:	85 db                	test   %ebx,%ebx
f01032aa:	7f ef                	jg     f010329b <printnum+0x7b>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01032ac:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032b0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01032b4:	8b 45 10             	mov    0x10(%ebp),%eax
f01032b7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01032bb:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01032c2:	00 
f01032c3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01032c6:	89 04 24             	mov    %eax,(%esp)
f01032c9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01032d0:	e8 8b 0a 00 00       	call   f0103d60 <__umoddi3>
f01032d5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032d9:	0f be 80 e8 4e 10 f0 	movsbl -0xfefb118(%eax),%eax
f01032e0:	89 04 24             	mov    %eax,(%esp)
f01032e3:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01032e6:	83 c4 3c             	add    $0x3c,%esp
f01032e9:	5b                   	pop    %ebx
f01032ea:	5e                   	pop    %esi
f01032eb:	5f                   	pop    %edi
f01032ec:	5d                   	pop    %ebp
f01032ed:	c3                   	ret    

f01032ee <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01032ee:	55                   	push   %ebp
f01032ef:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01032f1:	83 fa 01             	cmp    $0x1,%edx
f01032f4:	7e 0e                	jle    f0103304 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01032f6:	8b 10                	mov    (%eax),%edx
f01032f8:	8d 4a 08             	lea    0x8(%edx),%ecx
f01032fb:	89 08                	mov    %ecx,(%eax)
f01032fd:	8b 02                	mov    (%edx),%eax
f01032ff:	8b 52 04             	mov    0x4(%edx),%edx
f0103302:	eb 22                	jmp    f0103326 <getuint+0x38>
	else if (lflag)
f0103304:	85 d2                	test   %edx,%edx
f0103306:	74 10                	je     f0103318 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103308:	8b 10                	mov    (%eax),%edx
f010330a:	8d 4a 04             	lea    0x4(%edx),%ecx
f010330d:	89 08                	mov    %ecx,(%eax)
f010330f:	8b 02                	mov    (%edx),%eax
f0103311:	ba 00 00 00 00       	mov    $0x0,%edx
f0103316:	eb 0e                	jmp    f0103326 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103318:	8b 10                	mov    (%eax),%edx
f010331a:	8d 4a 04             	lea    0x4(%edx),%ecx
f010331d:	89 08                	mov    %ecx,(%eax)
f010331f:	8b 02                	mov    (%edx),%eax
f0103321:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103326:	5d                   	pop    %ebp
f0103327:	c3                   	ret    

f0103328 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103328:	55                   	push   %ebp
f0103329:	89 e5                	mov    %esp,%ebp
f010332b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010332e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103332:	8b 10                	mov    (%eax),%edx
f0103334:	3b 50 04             	cmp    0x4(%eax),%edx
f0103337:	73 0a                	jae    f0103343 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103339:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010333c:	88 0a                	mov    %cl,(%edx)
f010333e:	83 c2 01             	add    $0x1,%edx
f0103341:	89 10                	mov    %edx,(%eax)
}
f0103343:	5d                   	pop    %ebp
f0103344:	c3                   	ret    

f0103345 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103345:	55                   	push   %ebp
f0103346:	89 e5                	mov    %esp,%ebp
f0103348:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010334b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010334e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103352:	8b 45 10             	mov    0x10(%ebp),%eax
f0103355:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103359:	8b 45 0c             	mov    0xc(%ebp),%eax
f010335c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103360:	8b 45 08             	mov    0x8(%ebp),%eax
f0103363:	89 04 24             	mov    %eax,(%esp)
f0103366:	e8 02 00 00 00       	call   f010336d <vprintfmt>
	va_end(ap);
}
f010336b:	c9                   	leave  
f010336c:	c3                   	ret    

f010336d <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010336d:	55                   	push   %ebp
f010336e:	89 e5                	mov    %esp,%ebp
f0103370:	57                   	push   %edi
f0103371:	56                   	push   %esi
f0103372:	53                   	push   %ebx
f0103373:	83 ec 4c             	sub    $0x4c,%esp
f0103376:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103379:	8b 75 10             	mov    0x10(%ebp),%esi
f010337c:	eb 12                	jmp    f0103390 <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010337e:	85 c0                	test   %eax,%eax
f0103380:	0f 84 9f 03 00 00    	je     f0103725 <vprintfmt+0x3b8>
				return;
			putch(ch, putdat);
f0103386:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010338a:	89 04 24             	mov    %eax,(%esp)
f010338d:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103390:	0f b6 06             	movzbl (%esi),%eax
f0103393:	83 c6 01             	add    $0x1,%esi
f0103396:	83 f8 25             	cmp    $0x25,%eax
f0103399:	75 e3                	jne    f010337e <vprintfmt+0x11>
f010339b:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f010339f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01033a6:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f01033ab:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f01033b2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01033b7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01033ba:	eb 2b                	jmp    f01033e7 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033bc:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01033bf:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01033c3:	eb 22                	jmp    f01033e7 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033c5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01033c8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01033cc:	eb 19                	jmp    f01033e7 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033ce:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01033d1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01033d8:	eb 0d                	jmp    f01033e7 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01033da:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01033dd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01033e0:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033e7:	0f b6 16             	movzbl (%esi),%edx
f01033ea:	0f b6 c2             	movzbl %dl,%eax
f01033ed:	8d 7e 01             	lea    0x1(%esi),%edi
f01033f0:	89 7d e0             	mov    %edi,-0x20(%ebp)
f01033f3:	83 ea 23             	sub    $0x23,%edx
f01033f6:	80 fa 55             	cmp    $0x55,%dl
f01033f9:	0f 87 08 03 00 00    	ja     f0103707 <vprintfmt+0x39a>
f01033ff:	0f b6 d2             	movzbl %dl,%edx
f0103402:	ff 24 95 80 4f 10 f0 	jmp    *-0xfefb080(,%edx,4)
f0103409:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010340c:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0103413:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103418:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f010341b:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f010341f:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0103422:	8d 50 d0             	lea    -0x30(%eax),%edx
f0103425:	83 fa 09             	cmp    $0x9,%edx
f0103428:	77 2f                	ja     f0103459 <vprintfmt+0xec>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010342a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f010342d:	eb e9                	jmp    f0103418 <vprintfmt+0xab>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010342f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103432:	8d 50 04             	lea    0x4(%eax),%edx
f0103435:	89 55 14             	mov    %edx,0x14(%ebp)
f0103438:	8b 00                	mov    (%eax),%eax
f010343a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010343d:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103440:	eb 1a                	jmp    f010345c <vprintfmt+0xef>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103442:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0103445:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103449:	79 9c                	jns    f01033e7 <vprintfmt+0x7a>
f010344b:	eb 81                	jmp    f01033ce <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010344d:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103450:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0103457:	eb 8e                	jmp    f01033e7 <vprintfmt+0x7a>
f0103459:	89 7d d4             	mov    %edi,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010345c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103460:	79 85                	jns    f01033e7 <vprintfmt+0x7a>
f0103462:	e9 73 ff ff ff       	jmp    f01033da <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103467:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010346a:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010346d:	e9 75 ff ff ff       	jmp    f01033e7 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103472:	8b 45 14             	mov    0x14(%ebp),%eax
f0103475:	8d 50 04             	lea    0x4(%eax),%edx
f0103478:	89 55 14             	mov    %edx,0x14(%ebp)
f010347b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010347f:	8b 00                	mov    (%eax),%eax
f0103481:	89 04 24             	mov    %eax,(%esp)
f0103484:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103487:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010348a:	e9 01 ff ff ff       	jmp    f0103390 <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010348f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103492:	8d 50 04             	lea    0x4(%eax),%edx
f0103495:	89 55 14             	mov    %edx,0x14(%ebp)
f0103498:	8b 00                	mov    (%eax),%eax
f010349a:	89 c2                	mov    %eax,%edx
f010349c:	c1 fa 1f             	sar    $0x1f,%edx
f010349f:	31 d0                	xor    %edx,%eax
f01034a1:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01034a3:	83 f8 07             	cmp    $0x7,%eax
f01034a6:	7f 0b                	jg     f01034b3 <vprintfmt+0x146>
f01034a8:	8b 14 85 e0 50 10 f0 	mov    -0xfefaf20(,%eax,4),%edx
f01034af:	85 d2                	test   %edx,%edx
f01034b1:	75 23                	jne    f01034d6 <vprintfmt+0x169>
				printfmt(putch, putdat, "error %d", err);
f01034b3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034b7:	c7 44 24 08 00 4f 10 	movl   $0xf0104f00,0x8(%esp)
f01034be:	f0 
f01034bf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034c3:	8b 7d 08             	mov    0x8(%ebp),%edi
f01034c6:	89 3c 24             	mov    %edi,(%esp)
f01034c9:	e8 77 fe ff ff       	call   f0103345 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034ce:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01034d1:	e9 ba fe ff ff       	jmp    f0103390 <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f01034d6:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01034da:	c7 44 24 08 0c 4c 10 	movl   $0xf0104c0c,0x8(%esp)
f01034e1:	f0 
f01034e2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034e6:	8b 7d 08             	mov    0x8(%ebp),%edi
f01034e9:	89 3c 24             	mov    %edi,(%esp)
f01034ec:	e8 54 fe ff ff       	call   f0103345 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034f1:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01034f4:	e9 97 fe ff ff       	jmp    f0103390 <vprintfmt+0x23>
f01034f9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01034fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01034ff:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103502:	8b 45 14             	mov    0x14(%ebp),%eax
f0103505:	8d 50 04             	lea    0x4(%eax),%edx
f0103508:	89 55 14             	mov    %edx,0x14(%ebp)
f010350b:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010350d:	85 f6                	test   %esi,%esi
f010350f:	ba f9 4e 10 f0       	mov    $0xf0104ef9,%edx
f0103514:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0103517:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010351b:	0f 8e 8c 00 00 00    	jle    f01035ad <vprintfmt+0x240>
f0103521:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0103525:	0f 84 82 00 00 00    	je     f01035ad <vprintfmt+0x240>
				for (width -= strnlen(p, precision); width > 0; width--)
f010352b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010352f:	89 34 24             	mov    %esi,(%esp)
f0103532:	e8 61 03 00 00       	call   f0103898 <strnlen>
f0103537:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010353a:	29 c2                	sub    %eax,%edx
f010353c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
f010353f:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103543:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0103546:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0103549:	89 de                	mov    %ebx,%esi
f010354b:	89 d3                	mov    %edx,%ebx
f010354d:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010354f:	eb 0d                	jmp    f010355e <vprintfmt+0x1f1>
					putch(padc, putdat);
f0103551:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103555:	89 3c 24             	mov    %edi,(%esp)
f0103558:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010355b:	83 eb 01             	sub    $0x1,%ebx
f010355e:	85 db                	test   %ebx,%ebx
f0103560:	7f ef                	jg     f0103551 <vprintfmt+0x1e4>
f0103562:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103565:	89 f3                	mov    %esi,%ebx
f0103567:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f010356a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010356e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103573:	0f 49 45 e4          	cmovns -0x1c(%ebp),%eax
f0103577:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010357a:	29 c2                	sub    %eax,%edx
f010357c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010357f:	eb 2c                	jmp    f01035ad <vprintfmt+0x240>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103581:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103585:	74 18                	je     f010359f <vprintfmt+0x232>
f0103587:	8d 50 e0             	lea    -0x20(%eax),%edx
f010358a:	83 fa 5e             	cmp    $0x5e,%edx
f010358d:	76 10                	jbe    f010359f <vprintfmt+0x232>
					putch('?', putdat);
f010358f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103593:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010359a:	ff 55 08             	call   *0x8(%ebp)
f010359d:	eb 0a                	jmp    f01035a9 <vprintfmt+0x23c>
				else
					putch(ch, putdat);
f010359f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035a3:	89 04 24             	mov    %eax,(%esp)
f01035a6:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01035a9:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01035ad:	0f be 06             	movsbl (%esi),%eax
f01035b0:	83 c6 01             	add    $0x1,%esi
f01035b3:	85 c0                	test   %eax,%eax
f01035b5:	74 25                	je     f01035dc <vprintfmt+0x26f>
f01035b7:	85 ff                	test   %edi,%edi
f01035b9:	78 c6                	js     f0103581 <vprintfmt+0x214>
f01035bb:	83 ef 01             	sub    $0x1,%edi
f01035be:	79 c1                	jns    f0103581 <vprintfmt+0x214>
f01035c0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01035c3:	89 de                	mov    %ebx,%esi
f01035c5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01035c8:	eb 1a                	jmp    f01035e4 <vprintfmt+0x277>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01035ca:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035ce:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01035d5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01035d7:	83 eb 01             	sub    $0x1,%ebx
f01035da:	eb 08                	jmp    f01035e4 <vprintfmt+0x277>
f01035dc:	8b 7d 08             	mov    0x8(%ebp),%edi
f01035df:	89 de                	mov    %ebx,%esi
f01035e1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01035e4:	85 db                	test   %ebx,%ebx
f01035e6:	7f e2                	jg     f01035ca <vprintfmt+0x25d>
f01035e8:	89 7d 08             	mov    %edi,0x8(%ebp)
f01035eb:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035ed:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01035f0:	e9 9b fd ff ff       	jmp    f0103390 <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01035f5:	83 f9 01             	cmp    $0x1,%ecx
f01035f8:	7e 10                	jle    f010360a <vprintfmt+0x29d>
		return va_arg(*ap, long long);
f01035fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01035fd:	8d 50 08             	lea    0x8(%eax),%edx
f0103600:	89 55 14             	mov    %edx,0x14(%ebp)
f0103603:	8b 30                	mov    (%eax),%esi
f0103605:	8b 78 04             	mov    0x4(%eax),%edi
f0103608:	eb 26                	jmp    f0103630 <vprintfmt+0x2c3>
	else if (lflag)
f010360a:	85 c9                	test   %ecx,%ecx
f010360c:	74 12                	je     f0103620 <vprintfmt+0x2b3>
		return va_arg(*ap, long);
f010360e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103611:	8d 50 04             	lea    0x4(%eax),%edx
f0103614:	89 55 14             	mov    %edx,0x14(%ebp)
f0103617:	8b 30                	mov    (%eax),%esi
f0103619:	89 f7                	mov    %esi,%edi
f010361b:	c1 ff 1f             	sar    $0x1f,%edi
f010361e:	eb 10                	jmp    f0103630 <vprintfmt+0x2c3>
	else
		return va_arg(*ap, int);
f0103620:	8b 45 14             	mov    0x14(%ebp),%eax
f0103623:	8d 50 04             	lea    0x4(%eax),%edx
f0103626:	89 55 14             	mov    %edx,0x14(%ebp)
f0103629:	8b 30                	mov    (%eax),%esi
f010362b:	89 f7                	mov    %esi,%edi
f010362d:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103630:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103635:	85 ff                	test   %edi,%edi
f0103637:	0f 89 8c 00 00 00    	jns    f01036c9 <vprintfmt+0x35c>
				putch('-', putdat);
f010363d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103641:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103648:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010364b:	f7 de                	neg    %esi
f010364d:	83 d7 00             	adc    $0x0,%edi
f0103650:	f7 df                	neg    %edi
			}
			base = 10;
f0103652:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103657:	eb 70                	jmp    f01036c9 <vprintfmt+0x35c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103659:	89 ca                	mov    %ecx,%edx
f010365b:	8d 45 14             	lea    0x14(%ebp),%eax
f010365e:	e8 8b fc ff ff       	call   f01032ee <getuint>
f0103663:	89 c6                	mov    %eax,%esi
f0103665:	89 d7                	mov    %edx,%edi
			base = 10;
f0103667:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010366c:	eb 5b                	jmp    f01036c9 <vprintfmt+0x35c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010366e:	89 ca                	mov    %ecx,%edx
f0103670:	8d 45 14             	lea    0x14(%ebp),%eax
f0103673:	e8 76 fc ff ff       	call   f01032ee <getuint>
f0103678:	89 c6                	mov    %eax,%esi
f010367a:	89 d7                	mov    %edx,%edi
			base = 8;
f010367c:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0103681:	eb 46                	jmp    f01036c9 <vprintfmt+0x35c>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0103683:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103687:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010368e:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103691:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103695:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010369c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010369f:	8b 45 14             	mov    0x14(%ebp),%eax
f01036a2:	8d 50 04             	lea    0x4(%eax),%edx
f01036a5:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01036a8:	8b 30                	mov    (%eax),%esi
f01036aa:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01036af:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01036b4:	eb 13                	jmp    f01036c9 <vprintfmt+0x35c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01036b6:	89 ca                	mov    %ecx,%edx
f01036b8:	8d 45 14             	lea    0x14(%ebp),%eax
f01036bb:	e8 2e fc ff ff       	call   f01032ee <getuint>
f01036c0:	89 c6                	mov    %eax,%esi
f01036c2:	89 d7                	mov    %edx,%edi
			base = 16;
f01036c4:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01036c9:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f01036cd:	89 54 24 10          	mov    %edx,0x10(%esp)
f01036d1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01036d4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01036d8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036dc:	89 34 24             	mov    %esi,(%esp)
f01036df:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01036e3:	89 da                	mov    %ebx,%edx
f01036e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01036e8:	e8 33 fb ff ff       	call   f0103220 <printnum>
			break;
f01036ed:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01036f0:	e9 9b fc ff ff       	jmp    f0103390 <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01036f5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01036f9:	89 04 24             	mov    %eax,(%esp)
f01036fc:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01036ff:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103702:	e9 89 fc ff ff       	jmp    f0103390 <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103707:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010370b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103712:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103715:	eb 03                	jmp    f010371a <vprintfmt+0x3ad>
f0103717:	83 ee 01             	sub    $0x1,%esi
f010371a:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010371e:	75 f7                	jne    f0103717 <vprintfmt+0x3aa>
f0103720:	e9 6b fc ff ff       	jmp    f0103390 <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f0103725:	83 c4 4c             	add    $0x4c,%esp
f0103728:	5b                   	pop    %ebx
f0103729:	5e                   	pop    %esi
f010372a:	5f                   	pop    %edi
f010372b:	5d                   	pop    %ebp
f010372c:	c3                   	ret    

f010372d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010372d:	55                   	push   %ebp
f010372e:	89 e5                	mov    %esp,%ebp
f0103730:	83 ec 28             	sub    $0x28,%esp
f0103733:	8b 45 08             	mov    0x8(%ebp),%eax
f0103736:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103739:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010373c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103740:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103743:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010374a:	85 c0                	test   %eax,%eax
f010374c:	74 30                	je     f010377e <vsnprintf+0x51>
f010374e:	85 d2                	test   %edx,%edx
f0103750:	7e 2c                	jle    f010377e <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103752:	8b 45 14             	mov    0x14(%ebp),%eax
f0103755:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103759:	8b 45 10             	mov    0x10(%ebp),%eax
f010375c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103760:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103763:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103767:	c7 04 24 28 33 10 f0 	movl   $0xf0103328,(%esp)
f010376e:	e8 fa fb ff ff       	call   f010336d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103773:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103776:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103779:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010377c:	eb 05                	jmp    f0103783 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010377e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103783:	c9                   	leave  
f0103784:	c3                   	ret    

f0103785 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103785:	55                   	push   %ebp
f0103786:	89 e5                	mov    %esp,%ebp
f0103788:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010378b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010378e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103792:	8b 45 10             	mov    0x10(%ebp),%eax
f0103795:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103799:	8b 45 0c             	mov    0xc(%ebp),%eax
f010379c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01037a3:	89 04 24             	mov    %eax,(%esp)
f01037a6:	e8 82 ff ff ff       	call   f010372d <vsnprintf>
	va_end(ap);

	return rc;
}
f01037ab:	c9                   	leave  
f01037ac:	c3                   	ret    
f01037ad:	00 00                	add    %al,(%eax)
	...

f01037b0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01037b0:	55                   	push   %ebp
f01037b1:	89 e5                	mov    %esp,%ebp
f01037b3:	57                   	push   %edi
f01037b4:	56                   	push   %esi
f01037b5:	53                   	push   %ebx
f01037b6:	83 ec 1c             	sub    $0x1c,%esp
f01037b9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01037bc:	85 c0                	test   %eax,%eax
f01037be:	74 10                	je     f01037d0 <readline+0x20>
		cprintf("%s", prompt);
f01037c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037c4:	c7 04 24 0c 4c 10 f0 	movl   $0xf0104c0c,(%esp)
f01037cb:	e8 0a f7 ff ff       	call   f0102eda <cprintf>

	i = 0;
	echoing = iscons(0);
f01037d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01037d7:	e8 26 ce ff ff       	call   f0100602 <iscons>
f01037dc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01037de:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01037e3:	e8 09 ce ff ff       	call   f01005f1 <getchar>
f01037e8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01037ea:	85 c0                	test   %eax,%eax
f01037ec:	79 17                	jns    f0103805 <readline+0x55>
			cprintf("read error: %e\n", c);
f01037ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037f2:	c7 04 24 00 51 10 f0 	movl   $0xf0105100,(%esp)
f01037f9:	e8 dc f6 ff ff       	call   f0102eda <cprintf>
			return NULL;
f01037fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0103803:	eb 6d                	jmp    f0103872 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103805:	83 f8 08             	cmp    $0x8,%eax
f0103808:	74 05                	je     f010380f <readline+0x5f>
f010380a:	83 f8 7f             	cmp    $0x7f,%eax
f010380d:	75 19                	jne    f0103828 <readline+0x78>
f010380f:	85 f6                	test   %esi,%esi
f0103811:	7e 15                	jle    f0103828 <readline+0x78>
			if (echoing)
f0103813:	85 ff                	test   %edi,%edi
f0103815:	74 0c                	je     f0103823 <readline+0x73>
				cputchar('\b');
f0103817:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010381e:	e8 be cd ff ff       	call   f01005e1 <cputchar>
			i--;
f0103823:	83 ee 01             	sub    $0x1,%esi
f0103826:	eb bb                	jmp    f01037e3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103828:	83 fb 1f             	cmp    $0x1f,%ebx
f010382b:	7e 1f                	jle    f010384c <readline+0x9c>
f010382d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103833:	7f 17                	jg     f010384c <readline+0x9c>
			if (echoing)
f0103835:	85 ff                	test   %edi,%edi
f0103837:	74 08                	je     f0103841 <readline+0x91>
				cputchar(c);
f0103839:	89 1c 24             	mov    %ebx,(%esp)
f010383c:	e8 a0 cd ff ff       	call   f01005e1 <cputchar>
			buf[i++] = c;
f0103841:	88 9e 60 85 11 f0    	mov    %bl,-0xfee7aa0(%esi)
f0103847:	83 c6 01             	add    $0x1,%esi
f010384a:	eb 97                	jmp    f01037e3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010384c:	83 fb 0a             	cmp    $0xa,%ebx
f010384f:	74 05                	je     f0103856 <readline+0xa6>
f0103851:	83 fb 0d             	cmp    $0xd,%ebx
f0103854:	75 8d                	jne    f01037e3 <readline+0x33>
			if (echoing)
f0103856:	85 ff                	test   %edi,%edi
f0103858:	74 0c                	je     f0103866 <readline+0xb6>
				cputchar('\n');
f010385a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103861:	e8 7b cd ff ff       	call   f01005e1 <cputchar>
			buf[i] = 0;
f0103866:	c6 86 60 85 11 f0 00 	movb   $0x0,-0xfee7aa0(%esi)
			return buf;
f010386d:	b8 60 85 11 f0       	mov    $0xf0118560,%eax
		}
	}
}
f0103872:	83 c4 1c             	add    $0x1c,%esp
f0103875:	5b                   	pop    %ebx
f0103876:	5e                   	pop    %esi
f0103877:	5f                   	pop    %edi
f0103878:	5d                   	pop    %ebp
f0103879:	c3                   	ret    
f010387a:	00 00                	add    %al,(%eax)
f010387c:	00 00                	add    %al,(%eax)
	...

f0103880 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103880:	55                   	push   %ebp
f0103881:	89 e5                	mov    %esp,%ebp
f0103883:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103886:	b8 00 00 00 00       	mov    $0x0,%eax
f010388b:	eb 03                	jmp    f0103890 <strlen+0x10>
		n++;
f010388d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103890:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103894:	75 f7                	jne    f010388d <strlen+0xd>
		n++;
	return n;
}
f0103896:	5d                   	pop    %ebp
f0103897:	c3                   	ret    

f0103898 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103898:	55                   	push   %ebp
f0103899:	89 e5                	mov    %esp,%ebp
f010389b:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
f010389e:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01038a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01038a6:	eb 03                	jmp    f01038ab <strnlen+0x13>
		n++;
f01038a8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01038ab:	39 d0                	cmp    %edx,%eax
f01038ad:	74 06                	je     f01038b5 <strnlen+0x1d>
f01038af:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01038b3:	75 f3                	jne    f01038a8 <strnlen+0x10>
		n++;
	return n;
}
f01038b5:	5d                   	pop    %ebp
f01038b6:	c3                   	ret    

f01038b7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01038b7:	55                   	push   %ebp
f01038b8:	89 e5                	mov    %esp,%ebp
f01038ba:	53                   	push   %ebx
f01038bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01038be:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01038c1:	ba 00 00 00 00       	mov    $0x0,%edx
f01038c6:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01038ca:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01038cd:	83 c2 01             	add    $0x1,%edx
f01038d0:	84 c9                	test   %cl,%cl
f01038d2:	75 f2                	jne    f01038c6 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01038d4:	5b                   	pop    %ebx
f01038d5:	5d                   	pop    %ebp
f01038d6:	c3                   	ret    

f01038d7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01038d7:	55                   	push   %ebp
f01038d8:	89 e5                	mov    %esp,%ebp
f01038da:	53                   	push   %ebx
f01038db:	83 ec 08             	sub    $0x8,%esp
f01038de:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01038e1:	89 1c 24             	mov    %ebx,(%esp)
f01038e4:	e8 97 ff ff ff       	call   f0103880 <strlen>
	strcpy(dst + len, src);
f01038e9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01038ec:	89 54 24 04          	mov    %edx,0x4(%esp)
f01038f0:	01 d8                	add    %ebx,%eax
f01038f2:	89 04 24             	mov    %eax,(%esp)
f01038f5:	e8 bd ff ff ff       	call   f01038b7 <strcpy>
	return dst;
}
f01038fa:	89 d8                	mov    %ebx,%eax
f01038fc:	83 c4 08             	add    $0x8,%esp
f01038ff:	5b                   	pop    %ebx
f0103900:	5d                   	pop    %ebp
f0103901:	c3                   	ret    

f0103902 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103902:	55                   	push   %ebp
f0103903:	89 e5                	mov    %esp,%ebp
f0103905:	56                   	push   %esi
f0103906:	53                   	push   %ebx
f0103907:	8b 45 08             	mov    0x8(%ebp),%eax
f010390a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010390d:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103910:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103915:	eb 0f                	jmp    f0103926 <strncpy+0x24>
		*dst++ = *src;
f0103917:	0f b6 1a             	movzbl (%edx),%ebx
f010391a:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010391d:	80 3a 01             	cmpb   $0x1,(%edx)
f0103920:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103923:	83 c1 01             	add    $0x1,%ecx
f0103926:	39 f1                	cmp    %esi,%ecx
f0103928:	75 ed                	jne    f0103917 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010392a:	5b                   	pop    %ebx
f010392b:	5e                   	pop    %esi
f010392c:	5d                   	pop    %ebp
f010392d:	c3                   	ret    

f010392e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010392e:	55                   	push   %ebp
f010392f:	89 e5                	mov    %esp,%ebp
f0103931:	56                   	push   %esi
f0103932:	53                   	push   %ebx
f0103933:	8b 75 08             	mov    0x8(%ebp),%esi
f0103936:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103939:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010393c:	89 f0                	mov    %esi,%eax
f010393e:	85 d2                	test   %edx,%edx
f0103940:	75 0a                	jne    f010394c <strlcpy+0x1e>
f0103942:	eb 1d                	jmp    f0103961 <strlcpy+0x33>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103944:	88 18                	mov    %bl,(%eax)
f0103946:	83 c0 01             	add    $0x1,%eax
f0103949:	83 c1 01             	add    $0x1,%ecx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010394c:	83 ea 01             	sub    $0x1,%edx
f010394f:	74 0b                	je     f010395c <strlcpy+0x2e>
f0103951:	0f b6 19             	movzbl (%ecx),%ebx
f0103954:	84 db                	test   %bl,%bl
f0103956:	75 ec                	jne    f0103944 <strlcpy+0x16>
f0103958:	89 c2                	mov    %eax,%edx
f010395a:	eb 02                	jmp    f010395e <strlcpy+0x30>
f010395c:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f010395e:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0103961:	29 f0                	sub    %esi,%eax
}
f0103963:	5b                   	pop    %ebx
f0103964:	5e                   	pop    %esi
f0103965:	5d                   	pop    %ebp
f0103966:	c3                   	ret    

f0103967 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103967:	55                   	push   %ebp
f0103968:	89 e5                	mov    %esp,%ebp
f010396a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010396d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103970:	eb 06                	jmp    f0103978 <strcmp+0x11>
		p++, q++;
f0103972:	83 c1 01             	add    $0x1,%ecx
f0103975:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103978:	0f b6 01             	movzbl (%ecx),%eax
f010397b:	84 c0                	test   %al,%al
f010397d:	74 04                	je     f0103983 <strcmp+0x1c>
f010397f:	3a 02                	cmp    (%edx),%al
f0103981:	74 ef                	je     f0103972 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103983:	0f b6 c0             	movzbl %al,%eax
f0103986:	0f b6 12             	movzbl (%edx),%edx
f0103989:	29 d0                	sub    %edx,%eax
}
f010398b:	5d                   	pop    %ebp
f010398c:	c3                   	ret    

f010398d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010398d:	55                   	push   %ebp
f010398e:	89 e5                	mov    %esp,%ebp
f0103990:	53                   	push   %ebx
f0103991:	8b 45 08             	mov    0x8(%ebp),%eax
f0103994:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103997:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
f010399a:	eb 09                	jmp    f01039a5 <strncmp+0x18>
		n--, p++, q++;
f010399c:	83 ea 01             	sub    $0x1,%edx
f010399f:	83 c0 01             	add    $0x1,%eax
f01039a2:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01039a5:	85 d2                	test   %edx,%edx
f01039a7:	74 15                	je     f01039be <strncmp+0x31>
f01039a9:	0f b6 18             	movzbl (%eax),%ebx
f01039ac:	84 db                	test   %bl,%bl
f01039ae:	74 04                	je     f01039b4 <strncmp+0x27>
f01039b0:	3a 19                	cmp    (%ecx),%bl
f01039b2:	74 e8                	je     f010399c <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01039b4:	0f b6 00             	movzbl (%eax),%eax
f01039b7:	0f b6 11             	movzbl (%ecx),%edx
f01039ba:	29 d0                	sub    %edx,%eax
f01039bc:	eb 05                	jmp    f01039c3 <strncmp+0x36>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01039be:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01039c3:	5b                   	pop    %ebx
f01039c4:	5d                   	pop    %ebp
f01039c5:	c3                   	ret    

f01039c6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01039c6:	55                   	push   %ebp
f01039c7:	89 e5                	mov    %esp,%ebp
f01039c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01039cc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01039d0:	eb 07                	jmp    f01039d9 <strchr+0x13>
		if (*s == c)
f01039d2:	38 ca                	cmp    %cl,%dl
f01039d4:	74 0f                	je     f01039e5 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01039d6:	83 c0 01             	add    $0x1,%eax
f01039d9:	0f b6 10             	movzbl (%eax),%edx
f01039dc:	84 d2                	test   %dl,%dl
f01039de:	75 f2                	jne    f01039d2 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01039e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01039e5:	5d                   	pop    %ebp
f01039e6:	c3                   	ret    

f01039e7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01039e7:	55                   	push   %ebp
f01039e8:	89 e5                	mov    %esp,%ebp
f01039ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01039ed:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01039f1:	eb 07                	jmp    f01039fa <strfind+0x13>
		if (*s == c)
f01039f3:	38 ca                	cmp    %cl,%dl
f01039f5:	74 0a                	je     f0103a01 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01039f7:	83 c0 01             	add    $0x1,%eax
f01039fa:	0f b6 10             	movzbl (%eax),%edx
f01039fd:	84 d2                	test   %dl,%dl
f01039ff:	75 f2                	jne    f01039f3 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0103a01:	5d                   	pop    %ebp
f0103a02:	c3                   	ret    

f0103a03 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103a03:	55                   	push   %ebp
f0103a04:	89 e5                	mov    %esp,%ebp
f0103a06:	83 ec 0c             	sub    $0xc,%esp
f0103a09:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103a0c:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103a0f:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103a12:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103a15:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a18:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103a1b:	85 c9                	test   %ecx,%ecx
f0103a1d:	74 30                	je     f0103a4f <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103a1f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103a25:	75 25                	jne    f0103a4c <memset+0x49>
f0103a27:	f6 c1 03             	test   $0x3,%cl
f0103a2a:	75 20                	jne    f0103a4c <memset+0x49>
		c &= 0xFF;
f0103a2c:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103a2f:	89 d3                	mov    %edx,%ebx
f0103a31:	c1 e3 08             	shl    $0x8,%ebx
f0103a34:	89 d6                	mov    %edx,%esi
f0103a36:	c1 e6 18             	shl    $0x18,%esi
f0103a39:	89 d0                	mov    %edx,%eax
f0103a3b:	c1 e0 10             	shl    $0x10,%eax
f0103a3e:	09 f0                	or     %esi,%eax
f0103a40:	09 d0                	or     %edx,%eax
f0103a42:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103a44:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103a47:	fc                   	cld    
f0103a48:	f3 ab                	rep stos %eax,%es:(%edi)
f0103a4a:	eb 03                	jmp    f0103a4f <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103a4c:	fc                   	cld    
f0103a4d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103a4f:	89 f8                	mov    %edi,%eax
f0103a51:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103a54:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103a57:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103a5a:	89 ec                	mov    %ebp,%esp
f0103a5c:	5d                   	pop    %ebp
f0103a5d:	c3                   	ret    

f0103a5e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103a5e:	55                   	push   %ebp
f0103a5f:	89 e5                	mov    %esp,%ebp
f0103a61:	83 ec 08             	sub    $0x8,%esp
f0103a64:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103a67:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103a6a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a6d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a70:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103a73:	39 c6                	cmp    %eax,%esi
f0103a75:	73 36                	jae    f0103aad <memmove+0x4f>
f0103a77:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103a7a:	39 d0                	cmp    %edx,%eax
f0103a7c:	73 2f                	jae    f0103aad <memmove+0x4f>
		s += n;
		d += n;
f0103a7e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103a81:	f6 c2 03             	test   $0x3,%dl
f0103a84:	75 1b                	jne    f0103aa1 <memmove+0x43>
f0103a86:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103a8c:	75 13                	jne    f0103aa1 <memmove+0x43>
f0103a8e:	f6 c1 03             	test   $0x3,%cl
f0103a91:	75 0e                	jne    f0103aa1 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103a93:	83 ef 04             	sub    $0x4,%edi
f0103a96:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103a99:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103a9c:	fd                   	std    
f0103a9d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103a9f:	eb 09                	jmp    f0103aaa <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103aa1:	83 ef 01             	sub    $0x1,%edi
f0103aa4:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103aa7:	fd                   	std    
f0103aa8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103aaa:	fc                   	cld    
f0103aab:	eb 20                	jmp    f0103acd <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103aad:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103ab3:	75 13                	jne    f0103ac8 <memmove+0x6a>
f0103ab5:	a8 03                	test   $0x3,%al
f0103ab7:	75 0f                	jne    f0103ac8 <memmove+0x6a>
f0103ab9:	f6 c1 03             	test   $0x3,%cl
f0103abc:	75 0a                	jne    f0103ac8 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103abe:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103ac1:	89 c7                	mov    %eax,%edi
f0103ac3:	fc                   	cld    
f0103ac4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103ac6:	eb 05                	jmp    f0103acd <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103ac8:	89 c7                	mov    %eax,%edi
f0103aca:	fc                   	cld    
f0103acb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103acd:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103ad0:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103ad3:	89 ec                	mov    %ebp,%esp
f0103ad5:	5d                   	pop    %ebp
f0103ad6:	c3                   	ret    

f0103ad7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103ad7:	55                   	push   %ebp
f0103ad8:	89 e5                	mov    %esp,%ebp
f0103ada:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103add:	8b 45 10             	mov    0x10(%ebp),%eax
f0103ae0:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103ae4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ae7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103aeb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103aee:	89 04 24             	mov    %eax,(%esp)
f0103af1:	e8 68 ff ff ff       	call   f0103a5e <memmove>
}
f0103af6:	c9                   	leave  
f0103af7:	c3                   	ret    

f0103af8 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103af8:	55                   	push   %ebp
f0103af9:	89 e5                	mov    %esp,%ebp
f0103afb:	57                   	push   %edi
f0103afc:	56                   	push   %esi
f0103afd:	53                   	push   %ebx
f0103afe:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103b01:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103b04:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103b07:	ba 00 00 00 00       	mov    $0x0,%edx
f0103b0c:	eb 1a                	jmp    f0103b28 <memcmp+0x30>
		if (*s1 != *s2)
f0103b0e:	0f b6 04 17          	movzbl (%edi,%edx,1),%eax
f0103b12:	83 c2 01             	add    $0x1,%edx
f0103b15:	0f b6 4c 16 ff       	movzbl -0x1(%esi,%edx,1),%ecx
f0103b1a:	38 c8                	cmp    %cl,%al
f0103b1c:	74 0a                	je     f0103b28 <memcmp+0x30>
			return (int) *s1 - (int) *s2;
f0103b1e:	0f b6 c0             	movzbl %al,%eax
f0103b21:	0f b6 c9             	movzbl %cl,%ecx
f0103b24:	29 c8                	sub    %ecx,%eax
f0103b26:	eb 09                	jmp    f0103b31 <memcmp+0x39>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103b28:	39 da                	cmp    %ebx,%edx
f0103b2a:	75 e2                	jne    f0103b0e <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103b2c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b31:	5b                   	pop    %ebx
f0103b32:	5e                   	pop    %esi
f0103b33:	5f                   	pop    %edi
f0103b34:	5d                   	pop    %ebp
f0103b35:	c3                   	ret    

f0103b36 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103b36:	55                   	push   %ebp
f0103b37:	89 e5                	mov    %esp,%ebp
f0103b39:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b3c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103b3f:	89 c2                	mov    %eax,%edx
f0103b41:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103b44:	eb 07                	jmp    f0103b4d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103b46:	38 08                	cmp    %cl,(%eax)
f0103b48:	74 07                	je     f0103b51 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103b4a:	83 c0 01             	add    $0x1,%eax
f0103b4d:	39 d0                	cmp    %edx,%eax
f0103b4f:	72 f5                	jb     f0103b46 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103b51:	5d                   	pop    %ebp
f0103b52:	c3                   	ret    

f0103b53 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103b53:	55                   	push   %ebp
f0103b54:	89 e5                	mov    %esp,%ebp
f0103b56:	57                   	push   %edi
f0103b57:	56                   	push   %esi
f0103b58:	53                   	push   %ebx
f0103b59:	8b 55 08             	mov    0x8(%ebp),%edx
f0103b5c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103b5f:	eb 03                	jmp    f0103b64 <strtol+0x11>
		s++;
f0103b61:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103b64:	0f b6 02             	movzbl (%edx),%eax
f0103b67:	3c 20                	cmp    $0x20,%al
f0103b69:	74 f6                	je     f0103b61 <strtol+0xe>
f0103b6b:	3c 09                	cmp    $0x9,%al
f0103b6d:	74 f2                	je     f0103b61 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103b6f:	3c 2b                	cmp    $0x2b,%al
f0103b71:	75 0a                	jne    f0103b7d <strtol+0x2a>
		s++;
f0103b73:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103b76:	bf 00 00 00 00       	mov    $0x0,%edi
f0103b7b:	eb 10                	jmp    f0103b8d <strtol+0x3a>
f0103b7d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103b82:	3c 2d                	cmp    $0x2d,%al
f0103b84:	75 07                	jne    f0103b8d <strtol+0x3a>
		s++, neg = 1;
f0103b86:	8d 52 01             	lea    0x1(%edx),%edx
f0103b89:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103b8d:	85 db                	test   %ebx,%ebx
f0103b8f:	0f 94 c0             	sete   %al
f0103b92:	74 05                	je     f0103b99 <strtol+0x46>
f0103b94:	83 fb 10             	cmp    $0x10,%ebx
f0103b97:	75 15                	jne    f0103bae <strtol+0x5b>
f0103b99:	80 3a 30             	cmpb   $0x30,(%edx)
f0103b9c:	75 10                	jne    f0103bae <strtol+0x5b>
f0103b9e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103ba2:	75 0a                	jne    f0103bae <strtol+0x5b>
		s += 2, base = 16;
f0103ba4:	83 c2 02             	add    $0x2,%edx
f0103ba7:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103bac:	eb 13                	jmp    f0103bc1 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103bae:	84 c0                	test   %al,%al
f0103bb0:	74 0f                	je     f0103bc1 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103bb2:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103bb7:	80 3a 30             	cmpb   $0x30,(%edx)
f0103bba:	75 05                	jne    f0103bc1 <strtol+0x6e>
		s++, base = 8;
f0103bbc:	83 c2 01             	add    $0x1,%edx
f0103bbf:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103bc1:	b8 00 00 00 00       	mov    $0x0,%eax
f0103bc6:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103bc8:	0f b6 0a             	movzbl (%edx),%ecx
f0103bcb:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0103bce:	80 fb 09             	cmp    $0x9,%bl
f0103bd1:	77 08                	ja     f0103bdb <strtol+0x88>
			dig = *s - '0';
f0103bd3:	0f be c9             	movsbl %cl,%ecx
f0103bd6:	83 e9 30             	sub    $0x30,%ecx
f0103bd9:	eb 1e                	jmp    f0103bf9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0103bdb:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0103bde:	80 fb 19             	cmp    $0x19,%bl
f0103be1:	77 08                	ja     f0103beb <strtol+0x98>
			dig = *s - 'a' + 10;
f0103be3:	0f be c9             	movsbl %cl,%ecx
f0103be6:	83 e9 57             	sub    $0x57,%ecx
f0103be9:	eb 0e                	jmp    f0103bf9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0103beb:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0103bee:	80 fb 19             	cmp    $0x19,%bl
f0103bf1:	77 14                	ja     f0103c07 <strtol+0xb4>
			dig = *s - 'A' + 10;
f0103bf3:	0f be c9             	movsbl %cl,%ecx
f0103bf6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103bf9:	39 f1                	cmp    %esi,%ecx
f0103bfb:	7d 0e                	jge    f0103c0b <strtol+0xb8>
			break;
		s++, val = (val * base) + dig;
f0103bfd:	83 c2 01             	add    $0x1,%edx
f0103c00:	0f af c6             	imul   %esi,%eax
f0103c03:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103c05:	eb c1                	jmp    f0103bc8 <strtol+0x75>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103c07:	89 c1                	mov    %eax,%ecx
f0103c09:	eb 02                	jmp    f0103c0d <strtol+0xba>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103c0b:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103c0d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103c11:	74 05                	je     f0103c18 <strtol+0xc5>
		*endptr = (char *) s;
f0103c13:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c16:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103c18:	89 ca                	mov    %ecx,%edx
f0103c1a:	f7 da                	neg    %edx
f0103c1c:	85 ff                	test   %edi,%edi
f0103c1e:	0f 45 c2             	cmovne %edx,%eax
}
f0103c21:	5b                   	pop    %ebx
f0103c22:	5e                   	pop    %esi
f0103c23:	5f                   	pop    %edi
f0103c24:	5d                   	pop    %ebp
f0103c25:	c3                   	ret    
	...

f0103c30 <__udivdi3>:
f0103c30:	83 ec 1c             	sub    $0x1c,%esp
f0103c33:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103c37:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0103c3b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103c3f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103c43:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103c47:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103c4b:	85 ff                	test   %edi,%edi
f0103c4d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103c51:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c55:	89 cd                	mov    %ecx,%ebp
f0103c57:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c5b:	75 33                	jne    f0103c90 <__udivdi3+0x60>
f0103c5d:	39 f1                	cmp    %esi,%ecx
f0103c5f:	77 57                	ja     f0103cb8 <__udivdi3+0x88>
f0103c61:	85 c9                	test   %ecx,%ecx
f0103c63:	75 0b                	jne    f0103c70 <__udivdi3+0x40>
f0103c65:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c6a:	31 d2                	xor    %edx,%edx
f0103c6c:	f7 f1                	div    %ecx
f0103c6e:	89 c1                	mov    %eax,%ecx
f0103c70:	89 f0                	mov    %esi,%eax
f0103c72:	31 d2                	xor    %edx,%edx
f0103c74:	f7 f1                	div    %ecx
f0103c76:	89 c6                	mov    %eax,%esi
f0103c78:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103c7c:	f7 f1                	div    %ecx
f0103c7e:	89 f2                	mov    %esi,%edx
f0103c80:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c84:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c88:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c8c:	83 c4 1c             	add    $0x1c,%esp
f0103c8f:	c3                   	ret    
f0103c90:	31 d2                	xor    %edx,%edx
f0103c92:	31 c0                	xor    %eax,%eax
f0103c94:	39 f7                	cmp    %esi,%edi
f0103c96:	77 e8                	ja     f0103c80 <__udivdi3+0x50>
f0103c98:	0f bd cf             	bsr    %edi,%ecx
f0103c9b:	83 f1 1f             	xor    $0x1f,%ecx
f0103c9e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103ca2:	75 2c                	jne    f0103cd0 <__udivdi3+0xa0>
f0103ca4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0103ca8:	76 04                	jbe    f0103cae <__udivdi3+0x7e>
f0103caa:	39 f7                	cmp    %esi,%edi
f0103cac:	73 d2                	jae    f0103c80 <__udivdi3+0x50>
f0103cae:	31 d2                	xor    %edx,%edx
f0103cb0:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cb5:	eb c9                	jmp    f0103c80 <__udivdi3+0x50>
f0103cb7:	90                   	nop
f0103cb8:	89 f2                	mov    %esi,%edx
f0103cba:	f7 f1                	div    %ecx
f0103cbc:	31 d2                	xor    %edx,%edx
f0103cbe:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103cc2:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103cc6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103cca:	83 c4 1c             	add    $0x1c,%esp
f0103ccd:	c3                   	ret    
f0103cce:	66 90                	xchg   %ax,%ax
f0103cd0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103cd5:	b8 20 00 00 00       	mov    $0x20,%eax
f0103cda:	89 ea                	mov    %ebp,%edx
f0103cdc:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103ce0:	d3 e7                	shl    %cl,%edi
f0103ce2:	89 c1                	mov    %eax,%ecx
f0103ce4:	d3 ea                	shr    %cl,%edx
f0103ce6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103ceb:	09 fa                	or     %edi,%edx
f0103ced:	89 f7                	mov    %esi,%edi
f0103cef:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103cf3:	89 f2                	mov    %esi,%edx
f0103cf5:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103cf9:	d3 e5                	shl    %cl,%ebp
f0103cfb:	89 c1                	mov    %eax,%ecx
f0103cfd:	d3 ef                	shr    %cl,%edi
f0103cff:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d04:	d3 e2                	shl    %cl,%edx
f0103d06:	89 c1                	mov    %eax,%ecx
f0103d08:	d3 ee                	shr    %cl,%esi
f0103d0a:	09 d6                	or     %edx,%esi
f0103d0c:	89 fa                	mov    %edi,%edx
f0103d0e:	89 f0                	mov    %esi,%eax
f0103d10:	f7 74 24 0c          	divl   0xc(%esp)
f0103d14:	89 d7                	mov    %edx,%edi
f0103d16:	89 c6                	mov    %eax,%esi
f0103d18:	f7 e5                	mul    %ebp
f0103d1a:	39 d7                	cmp    %edx,%edi
f0103d1c:	72 22                	jb     f0103d40 <__udivdi3+0x110>
f0103d1e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103d22:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d27:	d3 e5                	shl    %cl,%ebp
f0103d29:	39 c5                	cmp    %eax,%ebp
f0103d2b:	73 04                	jae    f0103d31 <__udivdi3+0x101>
f0103d2d:	39 d7                	cmp    %edx,%edi
f0103d2f:	74 0f                	je     f0103d40 <__udivdi3+0x110>
f0103d31:	89 f0                	mov    %esi,%eax
f0103d33:	31 d2                	xor    %edx,%edx
f0103d35:	e9 46 ff ff ff       	jmp    f0103c80 <__udivdi3+0x50>
f0103d3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103d40:	8d 46 ff             	lea    -0x1(%esi),%eax
f0103d43:	31 d2                	xor    %edx,%edx
f0103d45:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d49:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d4d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d51:	83 c4 1c             	add    $0x1c,%esp
f0103d54:	c3                   	ret    
	...

f0103d60 <__umoddi3>:
f0103d60:	83 ec 1c             	sub    $0x1c,%esp
f0103d63:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103d67:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0103d6b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103d6f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103d73:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103d77:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103d7b:	85 ed                	test   %ebp,%ebp
f0103d7d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103d81:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d85:	89 cf                	mov    %ecx,%edi
f0103d87:	89 04 24             	mov    %eax,(%esp)
f0103d8a:	89 f2                	mov    %esi,%edx
f0103d8c:	75 1a                	jne    f0103da8 <__umoddi3+0x48>
f0103d8e:	39 f1                	cmp    %esi,%ecx
f0103d90:	76 4e                	jbe    f0103de0 <__umoddi3+0x80>
f0103d92:	f7 f1                	div    %ecx
f0103d94:	89 d0                	mov    %edx,%eax
f0103d96:	31 d2                	xor    %edx,%edx
f0103d98:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d9c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103da0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103da4:	83 c4 1c             	add    $0x1c,%esp
f0103da7:	c3                   	ret    
f0103da8:	39 f5                	cmp    %esi,%ebp
f0103daa:	77 54                	ja     f0103e00 <__umoddi3+0xa0>
f0103dac:	0f bd c5             	bsr    %ebp,%eax
f0103daf:	83 f0 1f             	xor    $0x1f,%eax
f0103db2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103db6:	75 60                	jne    f0103e18 <__umoddi3+0xb8>
f0103db8:	3b 0c 24             	cmp    (%esp),%ecx
f0103dbb:	0f 87 07 01 00 00    	ja     f0103ec8 <__umoddi3+0x168>
f0103dc1:	89 f2                	mov    %esi,%edx
f0103dc3:	8b 34 24             	mov    (%esp),%esi
f0103dc6:	29 ce                	sub    %ecx,%esi
f0103dc8:	19 ea                	sbb    %ebp,%edx
f0103dca:	89 34 24             	mov    %esi,(%esp)
f0103dcd:	8b 04 24             	mov    (%esp),%eax
f0103dd0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103dd4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103dd8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103ddc:	83 c4 1c             	add    $0x1c,%esp
f0103ddf:	c3                   	ret    
f0103de0:	85 c9                	test   %ecx,%ecx
f0103de2:	75 0b                	jne    f0103def <__umoddi3+0x8f>
f0103de4:	b8 01 00 00 00       	mov    $0x1,%eax
f0103de9:	31 d2                	xor    %edx,%edx
f0103deb:	f7 f1                	div    %ecx
f0103ded:	89 c1                	mov    %eax,%ecx
f0103def:	89 f0                	mov    %esi,%eax
f0103df1:	31 d2                	xor    %edx,%edx
f0103df3:	f7 f1                	div    %ecx
f0103df5:	8b 04 24             	mov    (%esp),%eax
f0103df8:	f7 f1                	div    %ecx
f0103dfa:	eb 98                	jmp    f0103d94 <__umoddi3+0x34>
f0103dfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e00:	89 f2                	mov    %esi,%edx
f0103e02:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103e06:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103e0a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103e0e:	83 c4 1c             	add    $0x1c,%esp
f0103e11:	c3                   	ret    
f0103e12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103e18:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e1d:	89 e8                	mov    %ebp,%eax
f0103e1f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0103e24:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0103e28:	89 fa                	mov    %edi,%edx
f0103e2a:	d3 e0                	shl    %cl,%eax
f0103e2c:	89 e9                	mov    %ebp,%ecx
f0103e2e:	d3 ea                	shr    %cl,%edx
f0103e30:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e35:	09 c2                	or     %eax,%edx
f0103e37:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103e3b:	89 14 24             	mov    %edx,(%esp)
f0103e3e:	89 f2                	mov    %esi,%edx
f0103e40:	d3 e7                	shl    %cl,%edi
f0103e42:	89 e9                	mov    %ebp,%ecx
f0103e44:	d3 ea                	shr    %cl,%edx
f0103e46:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e4b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103e4f:	d3 e6                	shl    %cl,%esi
f0103e51:	89 e9                	mov    %ebp,%ecx
f0103e53:	d3 e8                	shr    %cl,%eax
f0103e55:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e5a:	09 f0                	or     %esi,%eax
f0103e5c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103e60:	f7 34 24             	divl   (%esp)
f0103e63:	d3 e6                	shl    %cl,%esi
f0103e65:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103e69:	89 d6                	mov    %edx,%esi
f0103e6b:	f7 e7                	mul    %edi
f0103e6d:	39 d6                	cmp    %edx,%esi
f0103e6f:	89 c1                	mov    %eax,%ecx
f0103e71:	89 d7                	mov    %edx,%edi
f0103e73:	72 3f                	jb     f0103eb4 <__umoddi3+0x154>
f0103e75:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103e79:	72 35                	jb     f0103eb0 <__umoddi3+0x150>
f0103e7b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103e7f:	29 c8                	sub    %ecx,%eax
f0103e81:	19 fe                	sbb    %edi,%esi
f0103e83:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e88:	89 f2                	mov    %esi,%edx
f0103e8a:	d3 e8                	shr    %cl,%eax
f0103e8c:	89 e9                	mov    %ebp,%ecx
f0103e8e:	d3 e2                	shl    %cl,%edx
f0103e90:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e95:	09 d0                	or     %edx,%eax
f0103e97:	89 f2                	mov    %esi,%edx
f0103e99:	d3 ea                	shr    %cl,%edx
f0103e9b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103e9f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103ea3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103ea7:	83 c4 1c             	add    $0x1c,%esp
f0103eaa:	c3                   	ret    
f0103eab:	90                   	nop
f0103eac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103eb0:	39 d6                	cmp    %edx,%esi
f0103eb2:	75 c7                	jne    f0103e7b <__umoddi3+0x11b>
f0103eb4:	89 d7                	mov    %edx,%edi
f0103eb6:	89 c1                	mov    %eax,%ecx
f0103eb8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0103ebc:	1b 3c 24             	sbb    (%esp),%edi
f0103ebf:	eb ba                	jmp    f0103e7b <__umoddi3+0x11b>
f0103ec1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103ec8:	39 f5                	cmp    %esi,%ebp
f0103eca:	0f 82 f1 fe ff ff    	jb     f0103dc1 <__umoddi3+0x61>
f0103ed0:	e9 f8 fe ff ff       	jmp    f0103dcd <__umoddi3+0x6d>
